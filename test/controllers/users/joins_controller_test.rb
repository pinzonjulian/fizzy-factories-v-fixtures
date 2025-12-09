require "test_helper"

class Users::JoinsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    @david = create(:user, :david, account: @account, identity: @david_identity)
  end

  test "new" do
    sign_in_as @david

    get new_users_join_path
    assert_response :ok
  end

  test "create" do
    sign_in_as @david

    assert_no_difference -> { User.count } do
      post users_joins_path, params: { user: { name: "David Updated" } }
      assert_redirected_to landing_path
    end

    assert_equal "David Updated", @david.reload.name
  end
end
