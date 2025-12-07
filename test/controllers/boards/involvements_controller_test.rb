require "test_helper"

class Boards::InvolvementsControllerTest < ActionDispatch::IntegrationTest
  test "update" do
    account = Current.account
    kevin = create(:user, :kevin, account: account)
    board = create(:board, :writebook, account: account, creator: kevin)

    sign_in_as kevin

    board.access_for(kevin).access_only!

    assert_changes -> { board.access_for(kevin).involvement }, from: "access_only", to: "watching" do
      put board_involvement_path(board, involvement: "watching")
    end

    assert_response :success
  end
end
