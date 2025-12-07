require "test_helper"

class Cards::BoardsControllerTest < ActionDispatch::IntegrationTest
  test "update changes card board" do
    account = Current.account
    kevin_identity = create(:identity, :kevin)
    kevin = create(:user, :kevin, account: account, identity: kevin_identity)
    create(:user, :system, account: account)
    board = create(:board, :writebook, account: account, creator: kevin)
    column = create(:column, :writebook_triage, board: board, account: account)
    new_board = create(:board, :private, account: account, creator: kevin)

    card = with_current_user(kevin) do
      create(:card, :logo, board: board, column: column, account: account, creator: kevin)
    end

    sign_in_as kevin

    assert_not_equal new_board, card.board

    assert_changes -> { card.reload.board }, from: card.board, to: new_board do
      put card_board_path(card), params: { board_id: new_board.id }
    end

    assert_redirected_to card
  end
end
