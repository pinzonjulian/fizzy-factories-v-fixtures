require "test_helper"

class ReactionTest < ActiveSupport::TestCase
  setup do
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @account = Current.account

    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)
  end

  test "creating a reaction touches the card activity" do
    card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end

    comment = with_current_user(@david) do
      card.comments.create!(creator: @david)
    end

    assert_changes -> { card.reload.last_active_at } do
      comment.reactions.create!(content: "Nice!")
    end
  end
end
