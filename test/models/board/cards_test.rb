require "test_helper"

class Board::CardsTest < ActiveSupport::TestCase
  setup do
    @account = Current.account

    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    create(:user, :system, account: @account)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)

    with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end
  end

  test "touch cards when the name changes" do
    assert_changes -> { @board.cards.first.updated_at } do
      @board.update!(name: "New Name")
    end

    assert_no_changes -> { @board.cards.first.updated_at } do
      @board.update!(updated_at: 1.hour.from_now)
    end
  end
end
