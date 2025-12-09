require "test_helper"

class Columns::RightPositionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    @kevin_identity = create(:identity, :kevin)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @column_triage = create(:column, :writebook_triage, board: @board, account: @account, position: 0)
    @column_in_progress = create(:column, :writebook_in_progress, board: @board, account: @account, position: 1)
    @column_review = create(:column, :writebook_review, board: @board, account: @account, position: 2)

    sign_in_as @kevin
  end

  test "move column right" do
    columns = @board.columns.sorted.to_a

    column_a = columns[0]
    column_b = columns[1]
    original_position_a = column_a.position
    original_position_b = column_b.position

    post column_right_position_path(column_a), as: :turbo_stream
    assert_response :success

    assert_equal original_position_b, column_a.reload.position
    assert_equal original_position_a, column_b.reload.position
  end

  test "users can only reorder columns in boards they have access to" do
    post column_right_position_path(@column_triage), as: :turbo_stream
    assert_response :success

    @board.update! all_access: false
    @board.accesses.revoke_from @kevin

    post column_right_position_path(@column_triage), as: :turbo_stream
    assert_response :not_found
  end
end
