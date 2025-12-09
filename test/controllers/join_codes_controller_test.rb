require "test_helper"

class JoinCodesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    @kevin_identity = create(:identity, :kevin)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)

    @jz_identity = create(:identity, :jz)
    @jz = create(:user, :jz, account: @account, identity: @jz_identity)

    @join_code = @account.join_code
  end

  test "new" do
    get join_path(code: @join_code.code, script_name: @account.slug)

    assert_response :success
    assert_in_body @account.name
  end

  test "new with an invalid code" do
    get join_path(code: "INVALID-CODE", script_name: @account.slug)

    assert_response :not_found
  end

  test "new with an inactive code" do
    @join_code.update!(usage_count: @join_code.usage_limit)

    get join_path(code: @join_code.code, script_name: @account.slug)

    assert_response :gone
    assert_in_body "That code is all used up"
  end

  test "create" do
    assert_difference -> { Identity.count }, 1 do
      assert_difference -> { User.count }, 1 do
        post join_path(code: @join_code.code, script_name: @account.slug), params: { email_address: "new_user@example.com" }
      end
    end

    assert_redirected_to session_magic_link_url(script_name: nil)
    assert_equal new_users_verification_url(script_name: @account.slug), session[:return_to_after_authenticating]
  end

  test "create for existing identity" do
    sign_in_as @jz

    assert @jz_identity.users.exists?(account: @account), "JZ should be a member of account for this test"
    assert @jz_identity.users.find_by!(account: @account).setup?, "JZ's user should be setup for this test"

    assert_no_difference -> { Identity.count } do
      assert_no_difference -> { User.count } do
        post join_path(code: @join_code.code, script_name: @account.slug), params: { email_address: @jz_identity.email_address }
      end
    end

    assert_redirected_to landing_url(script_name: @account.slug)
  end

  test "create for signed-in identity without a user in the account redirects to verification" do
    # Create mike in a different account
    initech = create(:account, :initech)
    create(:user, :system_initech, account: initech)
    mike_identity = create(:identity, :mike)
    mike = create(:user, :mike, account: initech, identity: mike_identity)

    sign_in_as mike

    assert_not mike_identity.users.exists?(account: @account), "Mike should not be a member of account for this test"

    assert_no_difference -> { Identity.count } do
      assert_difference -> { User.count }, 1 do
        post join_path(code: @join_code.code, script_name: @account.slug), params: { email_address: mike_identity.email_address }
      end
    end

    assert_redirected_to new_users_verification_url(script_name: @account.slug)
  end

  test "create for different identity terminates existing session" do
    sign_in_as @kevin

    assert_difference -> { Identity.count }, 1 do
      assert_difference -> { User.count }, 1 do
        post join_path(code: @join_code.code, script_name: @account.slug), params: { email_address: "new_user@example.com" }
      end
    end

    assert_redirected_to session_magic_link_url(script_name: nil)
    assert_not_predicate cookies[:session_token], :present?
  end
end
