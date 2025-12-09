require "test_helper"

class ColumnTest < ActiveSupport::TestCase
  setup do
    @account = Current.account

    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    create(:user, :system, account: @account)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)
  end

  test "touch all the cards when the name or color changes" do
    card = with_current_user(@david) do
      @board.cards.create!(creator: @david, title: "Test Card", column: @column, status: :published)
    end

    assert_changes -> { card.reload.updated_at } do
      @column.update!(name: "New Name")
    end

    assert_changes -> { card.reload.updated_at } do
      @column.update!(color: "#FF0000")
    end

    assert_no_changes -> { card.reload.updated_at } do
      @column.update!(updated_at: 1.hour.from_now)
    end
  end

  test "touch all board cards when column is destroyed" do
    card = with_current_user(@david) do
      @board.cards.create!(creator: @david, title: "Test Card", column: @column, status: :published)
    end

    assert_changes -> { card.reload.updated_at } do
      @column.destroy
    end
  end
end
