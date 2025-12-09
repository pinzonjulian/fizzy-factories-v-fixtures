require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    @account = Current.account

    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    create(:user, :system, account: @account)
  end
end
