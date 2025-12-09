require "test_helper"

class Public::BoardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    @kevin_identity = create(:identity, :kevin)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)
    @board = create(:board, :writebook, account: @account, creator: @david)

    sign_in_as @kevin
    @board.publish
  end

  test "show" do
    get published_board_path(@board)
    assert_response :success
  end

  test "not found if the board is not published" do
    key = @board.publication.key

    @board.unpublish
    get public_board_path(key)

    assert_response :not_found
  end

  test "show works without authentication" do
    sign_out
    get published_board_path(@board)
    assert_response :success
  end
end
