require "test_helper"

class Public::Boards::ColumnsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_in_progress, account: @account, board: @board)

    @board.publish
  end

  test "show" do
    get public_board_column_path(@board.publication.key, @column)
    assert_response :success
  end
end
