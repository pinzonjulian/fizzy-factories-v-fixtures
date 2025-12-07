require "test_helper"

class Cards::GoldnessesControllerTest < ActionDispatch::IntegrationTest
  test "create" do
    account = Current.account
    kevin = create(:user, :kevin, account: account)
    board = create(:board, :writebook, account: account, creator: kevin)
    column = create(:column, :writebook_in_progress, board: board, account: account)
    text_card = with_current_user(kevin) do
      create(:card, :text, board: board, column: column, account: account, creator: kevin)
    end

    sign_in_as kevin

    assert_changes -> { text_card.reload.golden? }, from: false, to: true do
      post card_goldness_path(text_card), as: :turbo_stream
      assert_card_container_rerendered(text_card)
    end
  end

  test "destroy" do
    account = Current.account
    kevin = create(:user, :kevin, account: account)
    board = create(:board, :writebook, account: account, creator: kevin)
    column = create(:column, :writebook_triage, board: board, account: account)
    logo_card = with_current_user(kevin) do
      create(:card, :logo, board: board, column: column, account: account, creator: kevin)
    end
    create(:goldness, card: logo_card, account: account)

    sign_in_as kevin

    assert_changes -> { logo_card.reload.golden? }, from: true, to: false do
      delete card_goldness_path(logo_card), as: :turbo_stream
      assert_card_container_rerendered(logo_card)
    end
  end
end
