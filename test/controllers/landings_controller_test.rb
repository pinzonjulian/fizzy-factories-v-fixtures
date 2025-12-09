require "test_helper"

class LandingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    @kevin_identity = create(:identity, :kevin)

    @david = create(:user, :david, account: @account, identity: @david_identity)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)
    @board1 = create(:board, :writebook, account: @account, creator: @david)
    @board2 = create(:board, :private, account: @account, creator: @kevin)

    sign_in_as @kevin
  end

  test "redirects to the timeline when many boards" do
    get landing_path
    assert_redirected_to root_path
  end

  test "redirects to the timeline when no boards" do
    Board.destroy_all
    get landing_path
    assert_redirected_to root_path
  end

  test "redirects to boards when only one board" do
    sole_board, *boards_to_delete = @kevin.boards.to_a
    boards_to_delete.each(&:destroy)

    get landing_path
    assert_redirected_to board_path(sole_board)
  end
end
