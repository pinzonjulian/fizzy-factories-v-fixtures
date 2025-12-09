require "test_helper"

class Notifications::TraysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @system_user = create(:user, :system, account: @account)
    @identity_david = create(:identity, :david)
    @identity_kevin = create(:identity, :kevin)
    @david = create(:user, :david, account: @account, identity: @identity_david)
    @kevin = create(:user, :kevin, account: @account, identity: @identity_kevin)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, account: @account, board: @board)

    @card = with_current_user(@david) do
      create(:card, :layout, account: @account, board: @board, column: @column, creator: @david)
    end

    @comment = with_current_user(@david) do
      create(:comment, card: @card, creator: @david, account: @account)
    end

    @layout_commented_event = create(:event, account: @account, board: @board, eventable: @comment, creator: @david, action: "comment_created", created_at: 1.week.ago)
    @notification = create(:notification, user: @kevin, source: @layout_commented_event, creator: @david, account: @account, created_at: 1.week.ago)
    sign_in_as @kevin
  end

  test "show" do
    get tray_notifications_path

    assert_response :success
    assert_select "div", text: /Layout is broken/
  end
end
