require "test_helper"

class Notifications::UnsubscribesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @system_user = create(:user, :system, account: @account)
    @identity_david = create(:identity, :david)
    @david = create(:user, :david, account: @account, identity: @identity_david)
    @access_token = @david.generate_token_for(:unsubscribe)

    sign_in_as @david
  end

  test "new" do
    get new_notifications_unsubscribe_path(access_token: @access_token)
    assert_response :success
  end

  test "new with bad token" do
    get new_notifications_unsubscribe_path(access_token: "bad")
    assert_redirected_to root_path
  end

  test "create" do
    @david.reload.settings.bundle_email_every_few_hours!
    assert_changes -> { @david.reload.settings.bundle_email_frequency }, to: "never" do
      post notifications_unsubscribe_path(access_token: @access_token)
      assert_redirected_to notifications_unsubscribe_path(access_token: @access_token)
    end
  end

  test "create with bad token" do
    assert_no_changes -> { @david.reload.settings.bundle_email_frequency } do
      post notifications_unsubscribe_path(access_token: "bad")
      assert_redirected_to root_path
    end
  end

  test "show" do
    get notifications_unsubscribe_path(access_token: @access_token)
    assert_response :success
  end
end
