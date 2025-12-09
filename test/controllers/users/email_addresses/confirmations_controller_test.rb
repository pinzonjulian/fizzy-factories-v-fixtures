require "test_helper"

class Users::EmailAddresses::ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @old_email = @david.identity.email_address
    @new_email = "newemail@example.com"
    @token = @david.send(:generate_email_address_change_token, to: @new_email)
  end

  test "show" do
    get user_email_address_confirmation_path(user_id: @david.id, email_address_token: @token, script_name: @david.account.slug)
    assert_response :success
  end

  test "create" do
    post user_email_address_confirmation_path(user_id: @david.id, email_address_token: @token, script_name: @david.account.slug)

    assert_equal @new_email, @david.reload.identity.email_address
    assert_redirected_to edit_user_url(script_name: @david.account.slug, id: @david)
  end

  test "create with invalid token" do
    post user_email_address_confirmation_path(user_id: @david.id, email_address_token: "invalid", script_name: @david.account.slug)

    assert_equal @david.identity.email_address, @old_email
    assert_response :unprocessable_entity
    assert_match /Link expired/, response.body
  end
end
