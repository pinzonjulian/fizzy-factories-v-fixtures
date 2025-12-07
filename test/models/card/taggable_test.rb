require "test_helper"

class Card::TaggableTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)

    @card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end
  end

  test "toggle tag" do
    assert_difference -> { @card.tags.count }, 1 do
      @card.toggle_tag_with "ruby"
    end

    assert_equal "ruby", @card.tags.last.title

    assert_difference -> { @card.tags.count }, -1 do
      @card.toggle_tag_with "ruby"
    end
  end

  test "scope tags by account" do
    initech_account = create(:account, :initech)
    mike_identity = create(:identity, :mike)
    create(:user, :system, account: initech_account)
    mike = create(:user, :mike, account: initech_account, identity: mike_identity)
    initech_board = create(:board, :miltons_wish_list, account: initech_account, creator: mike)
    initech_column = create(:column, :writebook_triage, board: initech_board, account: initech_account)

    paycheck_card = Current.with_account(initech_account) do
      with_current_user(mike) do
        create(:card, :paycheck, board: initech_board, column: initech_column, account: initech_account, creator: mike)
      end
    end

    assert_difference -> { Tag.count }, 2 do
      @card.toggle_tag_with "ruby"
      paycheck_card.toggle_tag_with "ruby"
    end

    assert_not_equal @card.tags.last, paycheck_card.tags.last
  end
end
