require "test_helper"

class ExportMailerTest < ActionMailer::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    create(:user, :system, account: @account)
  end

  test "completed" do
    export = Account::Export.create!(account: @account, user: @david)
    email = ExportMailer.completed(export)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @david_identity.email_address ], email.to
    assert_equal "Your Fizzy data export is ready for download", email.subject
    assert_match %r{/exports/#{export.id}}, email.body.encoded
  end
end
