require "test_helper"

class Cards::TriagesControllerTest < ActionDispatch::IntegrationTest
  test "create" do
    account = Current.account
    kevin_identity = create(:identity, :kevin)
    kevin = create(:user, :kevin, account: account, identity: kevin_identity)
    create(:user, :system, account: account)
    board = create(:board, :writebook, account: account, creator: kevin)
    triage_column = create(:column, :writebook_triage, board: board, account: account)
    in_progress_column = create(:column, :writebook_in_progress, board: board, account: account)
    card = with_current_user(kevin) do
      create(:card, :logo, board: board, column: triage_column, account: account, creator: kevin)
    end

    sign_in_as kevin

    assert_changes -> { card.reload.column }, from: triage_column, to: in_progress_column do
      post card_triage_path(card, column_id: in_progress_column.id)
      assert_redirected_to card
    end
  end

  test "destroy" do
    account = Current.account
    kevin_identity = create(:identity, :kevin)
    kevin = create(:user, :kevin, account: account, identity: kevin_identity)
    create(:user, :system, account: account)
    board = create(:board, :writebook, account: account, creator: kevin)
    triage_column = create(:column, :writebook_triage, board: board, account: account)
    card = with_current_user(kevin) do
      create(:card, :shipping, board: board, column: triage_column, account: account, creator: kevin)
    end

    sign_in_as kevin

    assert_changes -> { card.reload.column }, to: nil do
      delete card_triage_path(card), as: :turbo_stream
      assert_redirected_to card
    end
  end
end
