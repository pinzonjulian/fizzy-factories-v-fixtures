require "test_helper"

class Card::Eventable::SystemCommenterTest < ActiveSupport::TestCase
  setup do
    @account = Current.account

    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    @kevin_identity = create(:identity, :kevin)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)

    create(:user, :system, account: @account)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_in_progress, board: @board, account: @account)

    @card = with_current_user(@kevin) do
      @board.cards.create! creator: @kevin, title: "The text is too small", column: @column, status: :published
    end
  end

  test "card_assigned" do
    assert_system_comment "David assigned this to Kevin" do
      @card.toggle_assignment @kevin
    end
  end

  test "card_unassigned" do
    @card.toggle_assignment @kevin
    @card.comments.destroy_all # To skip deduplication logic

    assert_system_comment "David unassigned from Kevin" do
      @card.toggle_assignment @kevin
    end
  end

  test "card_closed" do
    assert_system_comment "Moved to \u201CDone\u201D by David" do
      @card.close
    end
  end

  test "card_title_changed" do
    assert_system_comment "David changed the title from \u201CThe text is too small\u201D to \u201CMake text larger\u201D" do
      @card.update! title: "Make text larger"
    end
  end

  test "don't notify on system comments" do
    @card.watch_by(@david)

    assert_no_difference -> { Notification.count } do
      @card.toggle_assignment @kevin
    end
  end

  private
    def assert_system_comment(expected_comment)
      assert_difference -> { @card.comments.count }, 1 do
        yield
        comment = @card.comments.last
        assert comment.creator.system?
        assert_match Regexp.new(expected_comment.strip, Regexp::IGNORECASE), comment.body.to_plain_text.strip
      end
    end
end
