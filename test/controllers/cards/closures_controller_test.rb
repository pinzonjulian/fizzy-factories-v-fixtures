require "test_helper"

class Cards::ClosuresControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @kevin_identity = create(:identity, :kevin)
    Current.session = create(:session, identity: @kevin_identity)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)
    create(:user, :system, account: @account)
    @board = create(:board, :writebook, account: @account, creator: @kevin)
    @column = create(:column, :writebook_triage, board: @board, account: @account)

    sign_in_as @kevin
  end

  test "create" do
    card = with_current_user(@kevin) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @kevin)
    end

    assert_changes -> { card.reload.closed? }, from: false, to: true do
      post card_closure_path(card)
      assert_card_container_rerendered(card)
    end
  end

  test "destroy" do
    card = with_current_user(@kevin) do
      card = create(:card, :shipping, board: @board, column: @column, account: @account, creator: @kevin)
      create(:closure, card: card, user: @kevin, account: @account)
      card
    end

    assert_changes -> { card.reload.closed? }, from: true, to: false do
      delete card_closure_path(card)
      assert_card_container_rerendered(card)
    end
  end
end
