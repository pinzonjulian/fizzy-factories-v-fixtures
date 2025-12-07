require "test_helper"

class Boards::Columns::ClosedsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @kevin = create(:user, :kevin, account: @account)
    @board = create(:board, :writebook, account: @account, creator: @kevin)
    sign_in_as @kevin
  end

  test "show" do
    get board_columns_closed_path(@board)
    assert_response :success
  end
end
