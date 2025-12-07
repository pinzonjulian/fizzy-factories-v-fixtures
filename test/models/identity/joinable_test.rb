require "test_helper"

class Identity::JoinableTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    @other_account = create(:account, :initech)
  end

  test "join creates a new user and returns true" do
    assert_difference -> { User.count }, 1 do
      result = @david_identity.join(@other_account)
      assert result, "join should return true when creating a new user"
    end

    user = @david_identity.users.find_by!(account: @other_account)
    assert_equal @david_identity.email_address, user.name
  end

  test "join with custom attributes" do
    mike_identity = create(:identity, email_address: "mike@example.com")

    result = mike_identity.join(@account, name: "Mike")
    assert result

    user = mike_identity.users.find_by!(account: @account)
    assert_equal "Mike", user.name
  end

  test "join returns false if user already exists" do
    create(:user, :david, account: @account, identity: @david_identity)

    assert @david_identity.users.exists?(account: @account), "David should already be a member of account"

    assert_no_difference -> { User.count } do
      result = @david_identity.join(@account)
      assert_not result, "join should return false when user already exists"
    end
  end
end
