require "test_helper"

class MagicLinkMailerTest < ActionMailer::TestCase
  setup do
    @account = Current.account
    @kevin_identity = create(:identity, :kevin)
    create(:session, identity: @kevin_identity)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)
    create(:user, :system, account: @account)
  end

  test "sign_in_instructions" do
    magic_link = MagicLink.create!(identity: @kevin_identity)
    email = MagicLinkMailer.sign_in_instructions(magic_link)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @kevin_identity.email_address ], email.to
    assert_equal "Your Fizzy code is #{ magic_link.code }", email.subject
    assert_match magic_link.code, email.body.encoded
  end
end
