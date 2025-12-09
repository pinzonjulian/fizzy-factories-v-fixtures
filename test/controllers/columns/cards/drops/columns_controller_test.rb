require "test_helper"

class Columns::Cards::Drops::ColumnsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    create(:user, :system, account: @account)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @triage_column = create(:column, :writebook_triage, board: @board, account: @account)
    @in_progress_column = create(:column, :writebook_in_progress, board: @board, account: @account)

    sign_in_as @david
  end

  test "create" do
    card = with_current_user(@david) do
      create(:card, account: @account, board: @board, column: @triage_column, creator: @david, title: "Test card", status: "published")
    end

    assert_changes -> { card.reload.column }, to: @in_progress_column do
      post columns_card_drops_column_path(card, column_id: @in_progress_column.id), as: :turbo_stream
      assert_response :success
    end
  end
end
