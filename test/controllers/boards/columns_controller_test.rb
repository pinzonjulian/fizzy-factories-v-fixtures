require "test_helper"

class Boards::ColumnsControllerTest < ActionDispatch::IntegrationTest
  test "show" do
    account = Current.account
    kevin = create(:user, :kevin, account: account)
    board = create(:board, :writebook, account: account)
    column = create(:column, :writebook_in_progress, board: board, account: account)

    sign_in_as kevin

    get board_column_path(board, column)
    assert_response :success
  end

  test "create" do
    account = Current.account
    kevin = create(:user, :kevin, account: account)
    board = create(:board, :writebook, account: account)

    sign_in_as kevin

    assert_difference -> { board.columns.count }, +1 do
      post board_columns_path(board), params: { column: { name: "New Column" } }, as: :turbo_stream
      assert_response :success
    end

    assert_equal "New Column", board.columns.last.name
  end

  test "update" do
    account = Current.account
    kevin = create(:user, :kevin, account: account)
    board = create(:board, :writebook, account: account)
    column = create(:column, :writebook_in_progress, board: board, account: account)

    sign_in_as kevin

    assert_changes -> { column.reload.name }, from: "In progress", to: "Updated Name" do
      put board_column_path(board, column), params: { column: { name: "Updated Name" } }, as: :turbo_stream
      assert_response :success
    end
  end

  test "destroy" do
    account = Current.account
    kevin = create(:user, :kevin, account: account)
    board = create(:board, :writebook, account: account)
    column = create(:column, :writebook_on_hold, board: board, account: account)

    sign_in_as kevin

    assert_difference -> { board.columns.count }, -1 do
      delete board_column_path(board, column), as: :turbo_stream
      assert_response :success
    end
  end
end
