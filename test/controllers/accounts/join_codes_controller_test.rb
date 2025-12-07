require "test_helper"

class Account::JoinCodesControllerTest < ActionDispatch::IntegrationTest
  test "reset" do
    account = Current.account
    kevin = create(:user, :kevin, account: account)

    sign_in_as kevin

    get account_join_code_path
    assert_response :success

    assert_changes -> { Current.account.join_code.reload.code } do
      delete account_join_code_path
      assert_redirected_to account_join_code_path
    end
  end

  test "update" do
    account = Current.account
    kevin = create(:user, :kevin, account: account)

    sign_in_as kevin

    get edit_account_join_code_path
    assert_response :success

    put account_join_code_path, params: { account_join_code: { usage_limit: 5 } }
    assert_equal 5, Current.account.join_code.reload.usage_limit
    assert_redirected_to account_join_code_path
  end

  test "update requires admin" do
    account = Current.account
    kevin = create(:user, :kevin, account: account)
    david = create(:user, :david, account: account)

    sign_in_as kevin
    logout_and_sign_in_as david

    put account_join_code_path, params: { account_join_code: { usage_limit: 5 } }
    assert_response :forbidden
  end

  test "destroy requires admin" do
    account = Current.account
    kevin = create(:user, :kevin, account: account)
    david = create(:user, :david, account: account)

    sign_in_as kevin
    logout_and_sign_in_as david

    delete account_join_code_path
    assert_response :forbidden
  end
end
