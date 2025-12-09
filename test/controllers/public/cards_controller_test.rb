require "test_helper"

class Public::CardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    @kevin_identity = create(:identity, :kevin)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, account: @account, board: @board)
    @card = with_current_user(@david) do
      create(:card, :logo, account: @account, board: @board, column: @column, creator: @david)
    end

    sign_in_as @kevin
    @board.publish
  end

  test "show" do
    get public_board_card_path(@board.publication.key, @card)
    assert_response :success
  end

  test "not found if the board is not published" do
    @board.unpublish
    get public_board_card_path(@board.publication.key, @card)
    assert_response :not_found
  end
end
