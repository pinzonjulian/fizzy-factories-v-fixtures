require "test_helper"

class Boards::PublicationsControllerTest < ActionDispatch::IntegrationTest
  test "publish a board" do
    account = Current.account
    kevin = create(:user, :kevin, account: account)
    board = create(:board, :writebook, account: account, creator: kevin)

    sign_in_as kevin

    assert_not board.published?

    assert_changes -> { board.reload.published? }, from: false, to: true do
      post board_publication_path(board, format: :turbo_stream)
    end

    assert_turbo_stream action: :replace, target: dom_id(board, :publication)
  end

  test "unpublish a board" do
    account = Current.account
    kevin = create(:user, :kevin, account: account)
    board = create(:board, :writebook, account: account, creator: kevin)

    sign_in_as kevin

    board.publish
    assert board.published?

    assert_changes -> { board.reload.published? }, from: true, to: false do
      delete board_publication_path(board, format: :turbo_stream)
    end

    assert_turbo_stream action: :replace, target: dom_id(board, :publication)
  end

  test "publish requires board admin permission" do
    account = Current.account
    kevin = create(:user, :kevin, account: account)
    jz = create(:user, :jz, account: account)
    board = create(:board, :writebook, account: account, creator: kevin)

    sign_in_as kevin
    logout_and_sign_in_as jz

    assert_not board.published?

    post board_publication_path(board, format: :turbo_stream)

    assert_response :forbidden
    assert_not board.reload.published?
  end

  test "unpublish requires board admin permission" do
    account = Current.account
    kevin = create(:user, :kevin, account: account)
    jz = create(:user, :jz, account: account)
    board = create(:board, :writebook, account: account, creator: kevin)

    sign_in_as kevin
    logout_and_sign_in_as jz

    board.publish
    assert board.published?

    delete board_publication_path(board, format: :turbo_stream)

    assert_response :forbidden
    assert board.reload.published?
  end
end
