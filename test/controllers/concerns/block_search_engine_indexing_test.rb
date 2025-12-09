require "test_helper"

class BlockSearchEngineIndexingTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @board = create(:board, :writebook, account: @account, creator: @david)
  end

  test "sets X-Robots-Tag header to none on authenticated requests" do
    sign_in_as @david

    get board_path(@board)
    assert_response :success
    assert_equal "none", response.headers["X-Robots-Tag"]
  end

  test "sets X-Robots-Tag header to none on unauthenticated requests" do
    untenanted do
      get new_session_path
    end

    assert_response :success
    assert_equal "none", response.headers["X-Robots-Tag"]
  end

  test "sets X-Robots-Tag header to none on public board pages" do
    @board.publish

    get public_board_path(@board.publication.key)
    assert_response :success
    assert_equal "none", response.headers["X-Robots-Tag"]
  end
end
