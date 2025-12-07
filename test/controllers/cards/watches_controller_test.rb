require "test_helper"

class Cards::WatchesControllerTest < ActionDispatch::IntegrationTest
  test "create" do
    account = Current.account
    board = create(:board, :writebook, account: account)
    column = create(:column, :writebook_triage, board: board, account: account)
    kevin = create(:user, :kevin, account: account)
    david = create(:user, :david, account: account)

    sign_in_as kevin

    card = with_current_user(david) do
      create(:card, :logo, board: board, column: column, creator: david, account: account)
    end
    card.unwatch_by kevin

    assert_changes -> { card.watched_by?(kevin) }, from: false, to: true do
      post card_watch_path(card)
    end
  end

  test "destroy" do
    account = Current.account
    board = create(:board, :writebook, account: account)
    column = create(:column, :writebook_triage, board: board, account: account)
    kevin = create(:user, :kevin, account: account)
    david = create(:user, :david, account: account)

    sign_in_as kevin

    card = with_current_user(david) do
      create(:card, :logo, board: board, column: column, creator: david, account: account)
    end
    card.watch_by kevin

    assert_changes -> { card.watched_by?(kevin) }, from: true, to: false do
      delete card_watch_path(card)
    end
  end
end
