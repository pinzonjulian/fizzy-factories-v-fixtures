require "test_helper"

class Columns::Cards::Drops::ClosuresControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    create(:user, :system, account: @account)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @triage_column = create(:column, :writebook_triage, board: @board, account: @account)

    sign_in_as @david
  end

  test "create" do
    card = with_current_user(@david) do
      create(:card, account: @account, board: @board, column: @triage_column, creator: @david, title: "Test card", status: "published")
    end

    assert_changes -> { card.reload.closed? }, from: false, to: true do
      post columns_card_drops_closure_path(card), as: :turbo_stream
      assert_response :success
    end
  end
end
