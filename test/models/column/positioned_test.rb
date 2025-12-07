require "test_helper"

class Column::PositionedTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @column_a = create(:column, name: "Column A", color: "#000000", board: @board, account: @account, position: 0)
    @column_b = create(:column, name: "Column B", color: "#111111", board: @board, account: @account, position: 1)
    @column_c = create(:column, name: "Column C", color: "#222222", board: @board, account: @account, position: 2)
  end

  test "auto position new columns" do
    max_position = @board.columns.maximum(:position)

    new_column = @board.columns.create!(name: "New Column", color: "#000000")

    assert_equal max_position + 1, new_column.position
  end

  test "move column to the left" do
    original_position_a = @column_a.position
    original_position_b = @column_b.position

    @column_b.move_left

    assert_equal original_position_b, @column_a.reload.position
    assert_equal original_position_a, @column_b.reload.position
  end

  test "move left when already at leftmost position" do
    original_position = @column_a.position

    @column_a.move_left

    assert_equal original_position, @column_a.reload.position
  end

  test "move column to the right" do
    original_position_a = @column_a.position
    original_position_b = @column_b.position

    @column_a.move_right

    assert_equal original_position_b, @column_a.reload.position
    assert_equal original_position_a, @column_b.reload.position
  end

  test "move right when already at rightmost position" do
    original_position = @column_c.position

    @column_c.move_right

    assert_equal original_position, @column_c.reload.position
  end
end
