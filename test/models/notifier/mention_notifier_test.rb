require "test_helper"

class Notifier::MentionNotifierTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    @jz_identity = create(:identity, :jz)
    @kevin_identity = create(:identity, :kevin)
    Current.session = create(:session, identity: @david_identity)
    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @jz = create(:user, :jz, account: @account, identity: @jz_identity)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)

    @logo_card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end

    @layout_card = with_current_user(@david) do
      create(:card, :layout, board: @board, column: @column, account: @account, creator: @david)
    end
  end

  test "for returns the matching notifier class for the mention" do
    mention = @david.mentioned_by(@jz, at: @logo_card)

    assert_kind_of Notifier::MentionNotifier, Notifier.for(mention)
  end

  test "notify the mentionee" do
    @kevin.mentioned_by(@david, at: @logo_card)
    mention = @david.mentioned_by(@jz, at: @logo_card)

    assert_no_difference -> { @kevin.notifications.count } do
      Notifier.for(mention).notify
    end
  end

  test "create notifications for mentionee" do
    comment = with_current_user(@david) do
      @layout_card.comments.create!(creator: @david, account: @account)
    end
    event = create(:event, action: "comment_created", account: @account, creator: @david, board: @board, eventable: comment)

    assert_no_difference -> { @david.notifications.count } do
      Notifier.for(event).notify
    end
  end

  test "don't create notifications for self-mentions" do
    comment = with_current_user(@jz) do
      @layout_card.comments.create!(creator: @jz, account: @account)
    end
    event = create(:event, action: "comment_created", account: @account, creator: @jz, board: @board, eventable: comment)

    assert_no_difference -> { @jz.notifications.count } do
      Notifier.for(event).notify
    end
  end
end
