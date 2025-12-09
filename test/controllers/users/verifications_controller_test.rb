require "test_helper"

class Users::VerificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    @david = create(:user, :david, account: @account, identity: @david_identity)
  end

  test "new renders the auto-submit form" do
    sign_in_as @david

    get new_users_verification_path

    assert_response :ok
  end

  test "create verifies the user and redirects to join" do
    sign_in_as @david

    @david.update_column(:verified_at, nil)
    assert_not @david.verified?

    post users_verifications_path

    assert_redirected_to new_users_join_path
    assert @david.reload.verified?
  end
end
