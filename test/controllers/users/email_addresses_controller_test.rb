require "test_helper"

class Users::EmailAddressesControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @account = Current.account
    @david = create(:user, :david, account: @account)
    @kevin = create(:user, :kevin, account: @account)
    sign_in_as @david
  end

  test "new" do
    get new_user_email_address_path(@david, script_name: @david.account.slug)
    assert_response :success
  end

  test "create" do
    assert_emails 1 do
      post user_email_addresses_path(@david, script_name: @david.account.slug), params: { email_address: "newemail@example.com" }
    end
    assert_response :success
  end

  test "create with existing email in same account" do
    existing_email = @kevin.identity.email_address

    post user_email_addresses_path(@david, script_name: @david.account.slug), params: { email_address: existing_email }
    assert_redirected_to new_user_email_address_path(@david)
    assert_equal "You already have a user in this account with that email address", flash[:alert]
  end

  test "create for other user" do
    assert_no_emails do
      post user_email_addresses_path(@kevin, script_name: @david.account.slug), params: { email_address: "newemail@example.com" }
    end
    assert_response :not_found
  end
end
