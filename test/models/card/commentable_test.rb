require "test_helper"

class Card::CommentableTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @kevin_identity = create(:identity, :kevin)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)
  end

  test "creating a comment on a card makes the creator watch the card" do
    @board.access_for(@kevin).access_only!
    text_card = nil
    with_current_user(@david) do
      text_card = create(:card, :text, board: @board, column: @column, account: @account, creator: @david)
    end

    assert_not text_card.watched_by?(@kevin)

    with_current_user(@kevin) do
      text_card.comments.create!(body: "This sounds interesting!")
    end

    assert text_card.watched_by?(@kevin)
  end
end
