require "test_helper"

class Notifications::ReadingsControllerTest < ActionDispatch::IntegrationTest
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
      create(:card, :logo, account: @account, board: @board, column: @column, creator: @david)
    end

    @logo_published_event = create(:event, :logo_published, account: @account, board: @board, eventable: @card, creator: @david)
    @notification = create(:notification, user: @kevin, source: @logo_published_event, creator: @david, account: @account, created_at: 1.week.ago)
    sign_in_as @kevin
  end

  test "create" do
    assert_changes -> { @notification.reload.read? }, from: false, to: true do
      post notification_reading_path(@notification, format: :turbo_stream)
      assert_response :success
    end
  end

  test "destroy" do
    @notification.read

    assert_changes -> { @notification.reload.read? }, from: true, to: false do
      delete notification_reading_path(@notification, format: :turbo_stream)
      assert_response :success
    end
  end
end
