require "test_helper"

class Cards::PublishesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @kevin_identity = create(:identity, :kevin)
    Current.session = create(:session, identity: @kevin_identity)
    create(:user, :system, account: @account)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)
    @board = create(:board, :writebook, account: @account, creator: @kevin)
    @column = create(:column, :writebook_triage, board: @board, account: @account)
  end

  test "create" do
    card = with_current_user(@kevin) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @kevin)
    end

    sign_in_as @kevin
    card.drafted!

    assert_changes -> { card.reload.published? }, from: false, to: true do
      post card_publish_path(card)
    end

    assert_redirected_to card.board
  end

  test "create and add another" do
    card = with_current_user(@kevin) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @kevin)
    end

    sign_in_as @kevin
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
