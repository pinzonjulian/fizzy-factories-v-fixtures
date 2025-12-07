require "test_helper"

class Card::TriageableTest < ActiveSupport::TestCase
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
    @in_progress_column = create(:column, :writebook_in_progress, board: @board, account: @account)
  end

  test "active cards with columns are triaged" do
    logo = nil
    text = nil
    buy_domain = nil
    with_current_user(@david) do
      logo = create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
      text = create(:card, :text, board: @board, column: @in_progress_column, account: @account, creator: @kevin)
      buy_domain = create(:card, :buy_domain, board: @board, column: nil, account: @account, creator: @david)
    end

    assert logo.triaged?
    assert text.triaged?
    assert_not buy_domain.triaged?
  end

  test "active cards without columns are awaiting triage" do
    logo = nil
    text = nil
    buy_domain = nil
    with_current_user(@david) do
      logo = create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
      text = create(:card, :text, board: @board, column: @in_progress_column, account: @account, creator: @kevin)
      buy_domain = create(:card, :buy_domain, board: @board, column: nil, account: @account, creator: @david)
    end

    assert buy_domain.awaiting_triage?
    assert_not logo.awaiting_triage?
    assert_not text.awaiting_triage?
  end

  test "triage a card" do
    card = nil
    with_current_user(@david) do
      card = create(:card, :buy_domain, board: @board, column: nil, account: @account, creator: @david)
    end

    assert_nil card.column
    assert card.awaiting_triage?

    assert_difference -> { card.reload.events.where(action: "card_triaged").count }, +1 do
      card.triage_into(@in_progress_column)
    end

    assert_equal @in_progress_column, card.reload.column
    assert card.triaged?
  end

  test "cannot triage into a column from a different board" do
    card = nil
    with_current_user(@david) do
      card = create(:card, :buy_domain, board: @board, column: nil, account: @account, creator: @david)
    end

    private_board = create(:board, :private, account: @account, creator: @kevin)
    other_board_column = create(:column, name: "Other", color: "#000000", board: private_board, account: @account)

    assert_raises(RuntimeError, "The column must belong to the card board") do
      card.triage_into(other_board_column)
    end
  end

  test "send a card back to triage" do
    card = nil
    with_current_user(@david) do
      card = create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end

    assert card.triaged?

    assert_difference -> { card.reload.events.where(action: "card_sent_back_to_triage").count }, +1 do
      card.send_back_to_triage
    end

    assert card.reload.awaiting_triage?
  end

  test "scopes" do
    logo = nil
    text = nil
    buy_domain = nil
    with_current_user(@david) do
      logo = create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
      text = create(:card, :text, board: @board, column: @in_progress_column, account: @account, creator: @kevin)
      buy_domain = create(:card, :buy_domain, board: @board, column: nil, account: @account, creator: @david)
    end

    assert_includes Card.awaiting_triage, buy_domain
    assert_not_includes Card.awaiting_triage, logo
    assert_not_includes Card.awaiting_triage, text

    assert_includes Card.triaged, logo
    assert_includes Card.triaged, text
    assert_not_includes Card.triaged, buy_domain
  end
end
