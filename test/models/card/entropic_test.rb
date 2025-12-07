require "test_helper"

class Card::EntropicTest < ActiveSupport::TestCase
  setup do
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @account = Current.account
    @account_entropy = @account.entropy

    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    @kevin_identity = create(:identity, :kevin)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)
    @board_entropy = create(:entropy, container: @board, account: @account, auto_postpone_period: 90.days.to_i)

    @logo = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end

    @layout = with_current_user(@david) do
      create(:card, :layout, board: @board, column: @column, account: @account, creator: @david)
    end

    @shipping = with_current_user(@kevin) do
      create(:card, :shipping, board: @board, column: @column, account: @account, creator: @kevin)
    end

    # Setup for initech account (cross-account tests)
    @initech = create(:account, :initech)
    @initech_account_entropy = @initech.entropy
    create(:user, :system_initech, account: @initech)
    @mike_identity = create(:identity, :mike)
    @mike = create(:user, :mike, account: @initech, identity: @mike_identity)

    @miltons_wish_list = create(:board, :miltons_wish_list, account: @initech, creator: @mike)
    @initech_column = create(:column, name: "Triage", board: @miltons_wish_list, account: @initech)
    @miltons_wish_list_board_entropy = create(:entropy, container: @miltons_wish_list, account: @initech, auto_postpone_period: 90.days.to_i)

    # Create the radio card in the initech account context
    Current.with_account(@initech) do
      with_current_user(@mike) do
        @radio = create(:card, :radio, board: @miltons_wish_list, column: @initech_column, account: @initech, creator: @mike)
      end
    end
  end

  test "auto_postpone_at uses the period defined in the account by default" do
    freeze_time

    @board_entropy.destroy
    @account_entropy.reload.update! auto_postpone_period: 456.days
    @layout.update! last_active_at: 2.day.ago
    assert_equal (456 - 2).days.from_now, @layout.entropy.auto_clean_at
  end

  test "auto_postpone_at infers the period from the board when present" do
    freeze_time

    @board_entropy.update! auto_postpone_period: 123.days
    @layout.update! last_active_at: 2.day.ago
    assert_equal (123 - 2).days.from_now, @layout.reload.entropy.auto_clean_at
  end

  test "setting auto_postpone_period in the board without entropy will create it, without affecting the account entropy" do
    original_period = @account_entropy.auto_postpone_period

    @board_entropy.destroy
    @board.update! auto_postpone_period: 999.days

    assert_equal original_period, @account_entropy.reload.auto_postpone_period
  end

  test "auto postpone all due using the default account entropy" do
    @board_entropy.destroy

    @logo.update!(last_active_at: 1.day.ago - @account_entropy.auto_postpone_period)
    @shipping.update!(last_active_at: 1.day.from_now - @account_entropy.auto_postpone_period)

    assert_difference -> { Card.postponed.count }, +1 do
      Card.auto_postpone_all_due
    end

    assert @logo.reload.postponed?
    assert_equal @account.system_user, @logo.postponed_by
    assert_not @shipping.reload.postponed?
  end

  test "auto postpone all due using entropy defined at the board level" do
    @logo.update!(last_active_at: 1.day.ago - @board_entropy.auto_postpone_period)
    @shipping.update!(last_active_at: 1.day.from_now - @board_entropy.auto_postpone_period)

    assert_difference -> { Card.postponed.count }, +1 do
      Card.auto_postpone_all_due
    end

    assert @logo.reload.postponed?
    assert_not @shipping.reload.postponed?
  end

  test "postponing soon scope" do
    @logo.published!
    @shipping.published!

    @logo.update!(last_active_at: @board_entropy.auto_postpone_period.seconds.ago + 2.days)
    @shipping.update!(last_active_at: @board_entropy.auto_postpone_period.seconds.ago - 2.days)

    assert_includes Card.postponing_soon, @logo
    assert_not_includes Card.postponing_soon, @shipping
  end

  test "due_to_be_postponed scope works properly cross-account" do
    @logo.update!(last_active_at: @board_entropy.auto_postpone_period.seconds.ago - 2.days)
    @radio.update!(last_active_at: @miltons_wish_list_board_entropy.auto_postpone_period.seconds.ago - 2.days)

    assert_equal([@logo, @radio].to_set, Card.due_to_be_postponed.to_set)
  end

  test "postponing_soon scope works properly cross-account" do
    @logo.update!(last_active_at: @board_entropy.auto_postpone_period.seconds.ago + 2.days)
    @radio.update!(last_active_at: @miltons_wish_list_board_entropy.auto_postpone_period.seconds.ago + 2.days)

    assert_equal([@logo, @radio].to_set, Card.postponing_soon.to_set)
  end
end
