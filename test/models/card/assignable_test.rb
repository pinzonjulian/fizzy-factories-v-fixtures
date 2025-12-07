require "test_helper"

class Card::AssignableTest < ActiveSupport::TestCase
  test "assigning a user makes them watch the card" do
    account = FactoryBot.create(:account, :"37s")
    Current.account = account
    FactoryBot.create(:user, :system, account: account)
    david_identity = FactoryBot.create(:identity, :david)
    kevin_identity = FactoryBot.create(:identity, :kevin)
    jz_identity = FactoryBot.create(:identity, :jz)
    david = FactoryBot.create(:user, :david, account: account, identity: david_identity)
    kevin = FactoryBot.create(:user, :kevin, account: account, identity: kevin_identity)
    jz = FactoryBot.create(:user, :jz, account: account, identity: jz_identity)
    board = FactoryBot.create(:board, :writebook, account: account, creator: david)
    column = FactoryBot.create(:column, :writebook_triage, board: board, account: account)

    card = nil
    with_current_user(david) do
      card = FactoryBot.create(:card, :layout, board: board, column: column, account: account, creator: david)
    end

    assert_not card.assigned_to?(kevin)
    card.unwatch_by kevin

    with_current_user(jz) do
      card.toggle_assignment(kevin)
    end

    assert card.assigned_to?(kevin)
    assert card.watched_by?(kevin)
  end
end
