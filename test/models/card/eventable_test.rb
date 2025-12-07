require "test_helper"

class Card::EventableTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    create(:user, :system, account: @account)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)
  end

  test "new cards get the current time as the last activity time" do
    freeze_time

    card = with_current_user(@david) do
      create(:card, board: @board, column: @column, account: @account, creator: @david)
    end
    assert_equal Time.current, card.last_active_at
  end

  test "tracking events update the last activity time" do
    travel_to Time.current

    card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end
    card.close
    assert_equal Time.current, card.last_active_at
  end
end
