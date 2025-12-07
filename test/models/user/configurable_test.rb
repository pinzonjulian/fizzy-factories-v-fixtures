require "test_helper"

class User::ConfigurableTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
  end

  test "should create settings for new users" do
    user = create(:user, :david, account: @account)
    assert user.settings.present?
  end
end
