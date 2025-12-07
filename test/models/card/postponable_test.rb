require "test_helper"

class Card::PostponableTest < ActiveSupport::TestCase
  setup do
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @account = Current.account
    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)
  end

  test "check the postponed status of a card" do
    card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end

    assert_not card.postponed?
    assert card.active?

    card.postpone
    assert card.postponed?
    assert_not card.active?
  end

  test "postpone and resume a card" do
    card = with_current_user(@david) do
      create(:card, :text, board: @board, column: @column, account: @account, creator: @david)
    end

    assert_changes -> { card.reload.postponed? }, to: true do
      assert_difference -> { card.events.count }, +1 do
        card.postpone
      end
    end

    assert_equal @david, card.not_now.user
    assert card.events.last.action.card_postponed?

    assert_changes -> { card.reload.postponed? }, to: false do
      card.resume
    end
  end

  test "auto_postpone a card" do
    card = with_current_user(@david) do
      create(:card, :text, board: @board, column: @column, account: @account, creator: @david)
    end

    assert_changes -> { card.reload.postponed? }, to: true do
      assert_difference -> { card.events.count }, +1 do
        card.auto_postpone
      end
    end

    assert card.events.last.action.card_auto_postponed?
  end

  test "scopes" do
    logo = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end
    text = with_current_user(@david) do
      create(:card, :text, board: @board, column: @column, account: @account, creator: @david)
    end

    logo.postpone

    assert_includes Card.postponed, logo
    assert_not_includes Card.postponed, text

    assert_includes Card.active, text
    assert_not_includes Card.active, logo
  end
end
