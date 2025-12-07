require "test_helper"

class Card::GoldenTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @kevin_identity = create(:identity, :kevin)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)
  end

  test "check whether a card is golden" do
    logo = nil
    text = nil
    with_current_user(@david) do
      logo = create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
      create(:goldness, card: logo, account: @account)
      text = create(:card, :text, board: @board, column: @column, account: @account, creator: @kevin)
    end

    assert logo.golden?
    assert_not text.golden?
  end

  test "promote and demote from golden" do
    logo = nil
    text = nil
    with_current_user(@david) do
      logo = create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
      create(:goldness, card: logo, account: @account)
      text = create(:card, :text, board: @board, column: @column, account: @account, creator: @kevin)
    end

    assert_changes -> { text.reload.golden? }, to: true do
      text.gild
    end

    assert_changes -> { logo.reload.golden? }, to: false do
      logo.ungild
    end
  end

  test "scopes" do
    logo = nil
    text = nil
    with_current_user(@david) do
      logo = create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
      create(:goldness, card: logo, account: @account)
      text = create(:card, :text, board: @board, column: @column, account: @account, creator: @kevin)
    end

    assert_includes Card.golden, logo
    assert_not_includes Card.golden, text
  end

  test "gilding a card touches both the card and the board" do
    text = nil
    with_current_user(@david) do
      text = create(:card, :text, board: @board, column: @column, account: @account, creator: @kevin)
    end
    board = text.board

    card_updated_at = text.updated_at
    board_updated_at = board.updated_at

    travel 1.minute do
      text.gild
    end

    assert text.reload.updated_at > card_updated_at
    assert board.reload.updated_at > board_updated_at
  end
end
