require "test_helper"

class Column::ColoredTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    create(:user, :system, account: @account)
    @board = create(:board, :writebook, account: @account, creator: @david)
  end

  test "creates column with default color when color not provided" do
    column = @board.columns.create!(name: "New Column")

    assert_equal Column::Colored::DEFAULT_COLOR, column.color
  end

  test "update the column color" do
    column = create(:column, :writebook_triage, board: @board, account: @account)
    column.update!(color: "var(--color-card-3)")

    assert_not_nil column.color
    assert_equal Color.for_value("var(--color-card-3)"), column.color
  end
end
