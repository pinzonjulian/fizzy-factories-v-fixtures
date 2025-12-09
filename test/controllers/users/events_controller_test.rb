require "test_helper"

class Users::EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @david = create(:user, :david, account: @account)
    @kevin = create(:user, :kevin, account: @account)
    sign_in_as @kevin
  end

  test "show self" do
    get user_events_path(@kevin)
    assert_in_body "What have you been up to?"
  end

  test "show other" do
    get user_events_path(@david)
    assert_in_body "What has David been up to?"
  end
end
