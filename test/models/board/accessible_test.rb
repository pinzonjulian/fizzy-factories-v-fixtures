require "test_helper"

class Board::AccessibleTest < ActiveSupport::TestCase
  setup do
    @account = Current.account

    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    @kevin_identity = create(:identity, :kevin)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)

    @jz_identity = create(:identity, :jz)
    @jz = create(:user, :jz, account: @account, identity: @jz_identity)

    create(:user, :system, account: @account)

    @board = create(:board, :writebook, account: @account, creator: @david)
  end

  test "revising access" do
    @board.update! all_access: false

    @board.accesses.revise granted: [ @david, @jz ], revoked: [ @kevin ]
    assert_equal [ @david, @jz ].to_set, @board.users.to_set

    @board.accesses.grant_to @kevin
    assert_includes @board.users.reload, @kevin

    @board.accesses.revoke_from @kevin
    assert_not_includes @board.users.reload, @kevin
  end

  test "grants access to everyone after creation" do
    board = Current.set(session: Current.session, user: @david) do
      Board.create! name: "New board", all_access: true
    end
    assert_equal @account.users.active.sort, board.users.sort
  end

  test "grants access to everyone after update" do
    board = Current.set(session: Current.session, user: @david) do
      Board.create! name: "New board"
    end
    assert_equal [ @david ], board.users

    board.update! all_access: true
    assert_equal @account.users.active.sort, board.users.reload.sort
  end

  test "board watchers" do
    @board.access_for(@kevin).watching!
    assert_includes @board.watchers, @kevin

    @board.access_for(@kevin).access_only!
    assert_not_includes @board.reload.watchers, @kevin
  end

  # NOTE: The tests for clearing inaccessible data are in +AccessTest+
end
