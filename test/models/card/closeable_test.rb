require "test_helper"

class Card::CloseableTest < ActiveSupport::TestCase
  setup do
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
  end

  test "closed scope" do
    account = Current.account
    create(:user, :system, account: account)
    david = create(:user, :david, account: account, identity: @david_identity)
    kevin_identity = create(:identity, :kevin)
    kevin = create(:user, :kevin, account: account, identity: kevin_identity)
    board = create(:board, :writebook, account: account, creator: david)
    column = create(:column, :writebook_triage, board: board, account: account)

    open_card = nil
    shipping = nil
    with_current_user(david) do
      open_card = create(:card, :logo, board: board, column: column, account: account, creator: david)
      shipping = create(:card, :shipping, board: board, column: column, account: account, creator: kevin)
      create(:closure, card: shipping, user: kevin, account: account)
    end

    assert_equal [ shipping ], Card.closed
    assert_not_includes Card.open, shipping
  end

  test "close cards" do
    account = Current.account
    create(:user, :system, account: account)
    david = create(:user, :david, account: account, identity: @david_identity)
    kevin_identity = create(:identity, :kevin)
    kevin = create(:user, :kevin, account: account, identity: kevin_identity)
    board = create(:board, :writebook, account: account, creator: david)
    column = create(:column, :writebook_triage, board: board, account: account)

    logo = nil
    with_current_user(david) do
      logo = create(:card, :logo, board: board, column: column, account: account, creator: david)
    end

    assert_not logo.closed?

    assert_difference -> { logo.events.count }, +1 do
      logo.close(user: kevin)
    end

    assert logo.closed?
    assert logo.events.last.action.card_closed?
    assert_equal kevin, logo.closed_by
  end

  test "reopen cards" do
    account = Current.account
    create(:user, :system, account: account)
    david = create(:user, :david, account: account, identity: @david_identity)
    kevin_identity = create(:identity, :kevin)
    kevin = create(:user, :kevin, account: account, identity: kevin_identity)
    board = create(:board, :writebook, account: account, creator: david)
    column = create(:column, :writebook_triage, board: board, account: account)

    shipping = nil
    with_current_user(david) do
      shipping = create(:card, :shipping, board: board, column: column, account: account, creator: kevin)
      create(:closure, card: shipping, user: kevin, account: account)
    end

    assert shipping.closed?

    assert_difference -> { shipping.events.count }, +1 do
      shipping.reopen
    end
    assert shipping.reload.open?
    assert shipping.events.last.action.card_reopened?
  end
end
