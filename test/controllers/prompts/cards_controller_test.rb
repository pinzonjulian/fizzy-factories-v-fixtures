require "test_helper"

class Prompts::CardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @kevin = create(:user, :kevin, account: @account)
    sign_in_as @kevin
  end

  test "index" do
    get prompts_cards_path
    assert_response :success
  end
end
