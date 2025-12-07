require "test_helper"

class BoardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @kevin = create(:user, :kevin, account: @account)
    @david = create(:user, :david, account: @account)
    @jz = create(:user, :jz, account: @account)
    @writebook = create(:board, :writebook, account: @account, creator: @david)
    @private_board = create(:board, :private, account: @account, creator: @kevin)
    create(:entropy, account: @account, container: @writebook, auto_postpone_period: 90.days.to_i)
    create(:entropy, account: @account, container: @private_board, auto_postpone_period: 30.days.to_i)
    sign_in_as @kevin
  end

  test "new" do
    get new_board_path
    assert_response :success
  end

  test "show" do
    get board_path(@writebook)
    assert_response :success
  end

  test "create" do
    assert_difference -> { Board.count }, +1 do
      post boards_path, params: { board: { name: "Remodel Punch List" } }
    end

    board = Board.last
    assert_redirected_to board_path(board)
    assert_includes board.users, @kevin
    assert_equal "Remodel Punch List", board.name
  end

  test "edit" do
    get edit_board_path(@writebook)
    assert_response :success
  end

  test "update" do
    patch board_path(@writebook), params: {
      board: {
        name: "Writebook bugs",
        all_access: false,
        auto_postpone_period: 1.day
      },
      user_ids: [ @kevin, @jz ].pluck(:id)
    }

    assert_redirected_to edit_board_path(@writebook)
    assert_equal "Writebook bugs", @writebook.reload.name
    assert_equal [ @kevin, @jz ].sort, @writebook.users.sort
    assert_equal 1.day, @writebook.entropy.auto_postpone_period
    assert_not @writebook.all_access?
  end

  test "update redirects to root when user removes themselves from board" do
    patch board_path(@writebook), params: {
      board: { name: "Updated name", all_access: false },
      user_ids: [ @david, @jz ].pluck(:id)
    }

    assert_redirected_to root_path
    assert_not @writebook.reload.users.include?(@kevin)
  end

  test "update board with granular permissions, submitting no user ids" do
    assert_not @private_board.all_access?

    @private_board.users = [ @kevin ]
    @private_board.save!

    patch board_path(@private_board), params: {
      board: { name: "Renamed" }
    }

    assert_redirected_to edit_board_path(@private_board)
    assert_equal "Renamed", @private_board.reload.name
    assert_equal [ @kevin ], @private_board.users
    assert_not @private_board.all_access?
  end

  test "update all access" do
    board = Current.set(account: @account, session: @kevin.identity.sessions.first || create(:session, identity: @kevin.identity), user: @kevin) do
      Board.create! name: "New board", all_access: false
    end
    assert_equal [ @kevin ], board.users

    patch board_path(board), params: { board: { name: "Bugs", all_access: true } }

    assert_redirected_to edit_board_path(board)
    assert board.reload.all_access?
    assert_equal @account.users.active.sort, board.users.sort
  end

  test "destroy" do
    delete board_path(@writebook)
    assert_redirected_to root_path
    assert_raises(ActiveRecord::RecordNotFound) { @writebook.reload }
  end

  test "non-admin cannot change all_access on board they don't own" do
    logout_and_sign_in_as @jz

    original_all_access = @writebook.all_access

    patch board_path(@writebook), params: { board: { all_access: !original_all_access } }

    assert_response :forbidden
    assert_equal original_all_access, @writebook.reload.all_access
  end

  test "non-admin cannot change individual user accesses on board they don't own" do
    logout_and_sign_in_as @jz

    original_users = @writebook.users.sort

    patch board_path(@writebook), params: {
      board: { name: @writebook.name },
      user_ids: [ @jz.id ]
    }

    assert_response :forbidden
    assert_equal original_users, @writebook.reload.users.sort
  end

  test "non-admin cannot change board name on board they don't own" do
    logout_and_sign_in_as @jz

    original_name = @writebook.name

    patch board_path(@writebook), params: {
      board: { name: "Hacked Board Name" }
    }

    assert_response :forbidden
    assert_equal original_name, @writebook.reload.name
  end

  test "non-admin cannot destroy board they don't own" do
    logout_and_sign_in_as @jz

    delete board_path(@writebook)

    assert_response :forbidden
  end
end
