require "test_helper"

class Entropy::Test < ActiveSupport::TestCase
  setup do
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @account = Current.account

    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)

    @card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end
  end

  test "touch cards when entropy changes for board" do
    assert_changes -> { @board.cards.first.updated_at } do
      @board.entropy.update!(auto_postpone_period: 15.days)
    end
  end

  test "touch cards when entropy changes for account container" do
    assert_changes -> { @account.cards.first.updated_at } do
      @board.entropy.update!(auto_postpone_period: 15.days)
    end
  end
end
