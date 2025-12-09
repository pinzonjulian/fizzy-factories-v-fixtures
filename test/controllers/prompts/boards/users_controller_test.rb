require "test_helper"

class Prompts::Boards::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @kevin = create(:user, :kevin, account: @account)
    @david = create(:user, :david, account: @account)
    @jz = create(:user, :jz, account: @account)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @board.users = [ @kevin, @david, @jz ]
    sign_in_as @kevin
  end

  test "index" do
    get prompts_board_users_path(@board)
    assert_response :success
    assert_select "lexxy-prompt-item", count: 3
  end
end
