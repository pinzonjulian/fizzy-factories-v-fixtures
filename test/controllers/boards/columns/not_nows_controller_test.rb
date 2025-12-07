require "test_helper"

class Boards::Columns::NotNowsControllerTest < ActionDispatch::IntegrationTest
  test "show" do
    account = Current.account
    kevin = create(:user, :kevin, account: account)
    board = create(:board, :writebook, account: account)

    sign_in_as kevin

    get board_columns_not_now_path(board)
    assert_response :success
  end
end
