require "test_helper"

class IdentityTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @account = Current.account

    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    create(:user, :system, account: @account)
  end

  test "send_magic_link" do
    assert_emails 1 do
      magic_link = @david_identity.send_magic_link
      assert_not_nil magic_link
      assert_equal @david_identity, magic_link.identity
    end
  end

  test "email address format validation" do
    invalid_emails = [
      "sam smith@example.com",       # space in local part
      "@example.com",                # missing local part
      "test@",                       # missing domain
      "test",                        # missing @ and domain
      "<script>@example.com",        # angle brackets
      "test@example.com\nX-Inject:" # newline (header injection attempt)
    ]

    invalid_emails.each do |email|
      identity = Identity.new(email_address: email)
      assert_not identity.valid?, "expected #{email.inspect} to be invalid"
      assert identity.errors[:email_address].any?, "expected error on email_address for #{email.inspect}"
    end
  end

  test "join" do
    other_account = create(:account, :initech)
    create(:user, :system_initech, account: other_account)

    Current.without_account do
      assert_difference "User.count", 1 do
        @david_identity.join(other_account)
      end

      user = other_account.users.find_by!(identity: @david_identity)

      assert_not_nil user
      assert_equal @david_identity, user.identity
      assert_equal @david_identity.email_address, user.name
    end
  end
end
