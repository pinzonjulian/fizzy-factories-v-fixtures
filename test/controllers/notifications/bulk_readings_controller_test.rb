require "test_helper"

class Notifications::BulkReadingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @system_user = create(:user, :system, account: @account)
    @identity_david = create(:identity, :david)
    @identity_kevin = create(:identity, :kevin)
    @david = create(:user, :david, account: @account, identity: @identity_david)
    @kevin = create(:user, :kevin, account: @account, identity: @identity_kevin)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, account: @account, board: @board)

    @logo_card = with_current_user(@david) do
      create(:card, :logo, account: @account, board: @board, column: @column, creator: @david)
    end

    @layout_card = with_current_user(@david) do
      create(:card, :layout, account: @account, board: @board, column: @column, creator: @david)
    end

    @comment = with_current_user(@david) do
      create(:comment, card: @layout_card, creator: @david, account: @account)
    end

    @logo_published_event = create(:event, :logo_published, account: @account, board: @board, eventable: @logo_card, creator: @david)
    @layout_commented_event = create(:event, account: @account, board: @board, eventable: @comment, creator: @david, action: "comment_created", created_at: 1.week.ago)

    @logo_notification = create(:notification, user: @kevin, source: @logo_published_event, creator: @david, account: @account, created_at: 1.week.ago)
    @layout_notification = create(:notification, user: @kevin, source: @layout_commented_event, creator: @david, account: @account, created_at: 1.week.ago)

    sign_in_as @kevin
  end

  test "create marks all notifications as read" do
    assert_changes -> { @logo_notification.reload.read? }, from: false, to: true do
      assert_changes -> { @layout_notification.reload.read? }, from: false, to: true do
        post bulk_reading_path
      end
    end
  end

  test "create redirects to notifications path when not from tray" do
    post bulk_reading_path
    assert_redirected_to notifications_path
  end

  test "create returns ok when from tray" do
    post bulk_reading_path, params: { from_tray: true }
    assert_response :ok
  end
end
