require "test_helper"

class Public::Boards::Columns::NotNowsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @board = create(:board, :writebook, account: @account, creator: @david)

    @board.publish
  end

  test "show" do
    get public_board_columns_not_now_path(@board.publication.key)
    assert_response :success
  end
end
