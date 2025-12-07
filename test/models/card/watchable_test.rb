require "test_helper"

class Card::WatchableTest < ActiveSupport::TestCase
  setup do
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @account = Current.account

    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    @kevin_identity = create(:identity, :kevin)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)

    @jz_identity = create(:identity, :jz)
    @jz = create(:user, :jz, account: @account, identity: @jz_identity)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)

    Watch.destroy_all
    Access.all.update!(involvement: :access_only)
  end

  test "watched_by?" do
    logo = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end

    assert_not logo.watched_by?(@kevin)

    logo.watch_by @kevin
    assert logo.watched_by?(@kevin)

    logo.unwatch_by @kevin
    assert_not logo.watched_by?(@kevin)
  end

  test "cards are initially watched by their creator" do
    card = with_current_user(@kevin) do
      @board.cards.create!(creator: @kevin)
    end

    assert card.watched_by?(@kevin)
  end

  test "watchers" do
    logo = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end

    @board.access_for(@kevin).watching!
    @board.access_for(@jz).watching!

    logo.watch_by @kevin
    logo.unwatch_by @jz
    logo.watch_by @david

    assert_equal [ @kevin, @david ].sort, logo.watchers.sort

    # Only active users
    @david.system!
    assert_equal [ @kevin ].sort, logo.watchers.reload.sort
  end
end
