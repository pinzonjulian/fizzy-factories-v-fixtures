require "test_helper"

class Cards::NotNowsControllerTest < ActionDispatch::IntegrationTest
  test "create" do
    account = Current.account
    kevin_identity = create(:identity, :kevin)
    kevin = create(:user, :kevin, account: account, identity: kevin_identity)
    david = create(:user, :david, account: account)
    create(:user, :system, account: account)
    board = create(:board, :writebook, account: account, creator: kevin)
    column = create(:column, :writebook_triage, board: board, account: account)

    card = with_current_user(david) do
      create(:card, :logo, board: board, column: column, creator: david, account: account)
    end

    sign_in_as kevin

    assert_changes -> { card.reload.postponed? }, from: false, to: true do
      post card_not_now_path(card)
      assert_card_container_rerendered(card)
    end
  end
end
