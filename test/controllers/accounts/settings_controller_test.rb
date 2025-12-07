require "test_helper"

class Account::SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @kevin = create(:user, :kevin, account: @account)
  end

  test "show" do
    sign_in_as @kevin

    get account_settings_path
    assert_response :success
  end

  test "update" do
    sign_in_as @kevin

    put account_settings_path, params: { account: { name: "New Account Name" } }
    assert_equal "New Account Name", Current.account.reload.name
    assert_redirected_to account_settings_path
  end

  test "update requires admin" do
    david = create(:user, :david, account: @account)

    sign_in_as @kevin
    logout_and_sign_in_as david

    put account_settings_path, params: { account: { name: "New Account Name" } }
    assert_response :forbidden
  end
end
