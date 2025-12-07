require "test_helper"

class User::EmailAddressChangeableTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @account = Current.account
    @kevin_identity = create(:identity, :kevin)
    Current.session = create(:session, identity: @kevin_identity)
    create(:user, :system, account: @account)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)

    @new_email = "newart@example.com"
    @old_email = @kevin_identity.email_address
  end

  test "send_email_address_change_confirmation" do
    assert_emails 1 do
      @kevin.send_email_address_change_confirmation(@new_email)
    end
  end

  test "change_email_address" do
    old_identity = @kevin_identity
    mike_identity = create(:identity, :mike)

    assert_difference -> { Identity.count }, +1 do
      @kevin.change_email_address(@new_email)
    end

    assert_equal @new_email, @kevin.reload.identity.email_address
    assert_not old_identity.reload.users.exists?(id: @kevin.id)
    assert_equal @new_email, @kevin.reload.identity.email_address

    assert_no_difference -> { Identity.count } do
      @kevin.change_email_address(mike_identity.email_address)
    end
    assert_equal mike_identity.email_address, @kevin.reload.identity.email_address
  end

  test "change_email_address_using_token" do
    token = @kevin.send(:generate_email_address_change_token, to: @new_email)

    @kevin.change_email_address_using_token(token)

    assert_equal @new_email, @kevin.reload.identity.email_address
  end

  test "change_email_address_using_token with invalid token" do
    assert_not @kevin.change_email_address_using_token("invalid_token")
    assert_equal @old_email, @kevin.reload.identity.email_address

    token = @kevin.send(:generate_email_address_change_token, to: @new_email)
    old_email = "#{SecureRandom.hex(16)}@example.com"
    @kevin_identity.update!(email_address: old_email)
    @kevin.reload

    assert_not @kevin.change_email_address_using_token(token)
    assert_equal old_email, @kevin.reload.identity.email_address
  end
end
