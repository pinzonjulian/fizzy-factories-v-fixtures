require "test_helper"

class User::AccessorTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @writebook = create(:board, :writebook, account: @account, creator: @david)
  end

  test "new users get added to all_access boards on creation" do
    user = User.create!(account: @account, name: "Jorge")

    assert_includes user.boards, @writebook
    assert_equal user.account.boards.all_access.count, user.boards.count
  end

  test "system user does not get added to boards on creation" do
    system_user = User.create!(account: @account, role: "system", name: "Test System User")
    assert_empty system_user.boards
  end
end
