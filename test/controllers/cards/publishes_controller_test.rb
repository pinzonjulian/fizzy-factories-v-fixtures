require "test_helper"

class Cards::PublishesControllerTest < ActionDispatch::IntegrationTest
  test "create" do
    account = Current.account
    board = create(:board, :writebook, account: account)
    column = create(:column, :writebook_triage, board: board, account: account)
    kevin = create(:user, :kevin, account: account)
    card = create(:card, :logo, board: board, column: column, account: account)

    sign_in_as kevin
    card.drafted!

    assert_changes -> { card.reload.published? }, from: false, to: true do
      post card_publish_path(card)
    end

    assert_redirected_to card.board
  end

  test "create and add another" do
    account = Current.account
    board = create(:board, :writebook, account: account)
    column = create(:column, :writebook_triage, board: board, account: account)
    kevin = create(:user, :kevin, account: account)
    card = create(:card, :logo, board: board, column: column, account: account)

    sign_in_as kevin
    card.drafted!

    assert_changes -> { card.reload.published? }, from: false, to: true do
      assert_difference -> { Card.count }, +1 do
        post card_publish_path(card, creation_type: "add_another")
      end
    end

    new_card = Card.last
    assert new_card.drafted?
    assert_redirected_to new_card
  end
end
