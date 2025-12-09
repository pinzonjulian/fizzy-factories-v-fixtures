require "test_helper"

class Users::RolesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @david = create(:user, :david, account: @account)
    @kevin = create(:user, :kevin, account: @account)
    @jason = create(:user, :jason, account: @account)
    sign_in_as @kevin
  end

  test "update" do
    assert_not @david.admin?

    put user_role_path(@david), params: { user: { role: "admin" } }

    assert_redirected_to users_path
    assert @david.reload.admin?
  end

  test "can't promote to special roles" do
    assert_no_changes -> { @david.reload.role } do
      put user_role_path(@david), params: { user: { role: "system" } }
    end

    assert_no_changes -> { @david.reload.role } do
      put user_role_path(@david), params: { user: { role: "owner" } }
    end
  end

  test "admin cannot demote the owner" do
    assert @jason.owner?

    assert_no_changes -> { @jason.reload.role } do
      put user_role_path(@jason), params: { user: { role: "admin" } }
    end

    assert_response :forbidden
  end

  test "admin cannot change owner role to member" do
    assert @jason.owner?

    assert_no_changes -> { @jason.reload.role } do
      put user_role_path(@jason), params: { user: { role: "member" } }
    end

    assert_response :forbidden
  end
end
