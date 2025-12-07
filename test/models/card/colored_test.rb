require "test_helper"

class Card::ColoredTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)
  end

  test "use default color if no column" do
    card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end
    card.update! column: nil
    assert_equal Column::Colored::DEFAULT_COLOR, card.color
  end

  test "infer color from column" do
    card = with_current_user(@david) do
      create(:card, :layout, board: @board, column: @column, account: @account, creator: @david)
    end
    assert_equal card.column.color, card.color
  end
end
