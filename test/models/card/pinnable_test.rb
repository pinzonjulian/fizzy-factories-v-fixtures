require "test_helper"

class Card::PinnableTest < ActiveSupport::TestCase
  setup do
    @account = Current.account

    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    @kevin_identity = create(:identity, :kevin)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)

    create(:user, :system, account: @account)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @private_board = create(:board, :private, account: @account, creator: @kevin)
    @column = create(:column, :writebook_triage, board: @board, account: @account)
    @in_progress_column = create(:column, :writebook_in_progress, board: @board, account: @account)

    with_current_user(@david) do
      @card = create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end

    @pin = create(:pin, account: @account, card: @card, user: @kevin)
  end

  test "broadcasts pin update when title changes" do
    assert_broadcasted_pin_update do
      @card.update!(title: "New title")
    end
  end

  test "broadcasts pin update when column changes" do
    assert_broadcasted_pin_update do
      @card.update!(column: @in_progress_column)
    end
  end

  test "broadcasts pin update when board changes" do
    assert_broadcasted_pin_update do
      @card.update!(board: @private_board, column: nil)
    end
  end

  test "does not broadcast pin update when other properties change" do
    perform_enqueued_jobs do
      assert_turbo_stream_broadcasts([ @pin.user, :pins_tray ], count: 0) do
        @card.update!(last_active_at: Time.current)
      end
    end
  end

  private
    def assert_broadcasted_pin_update(&block)
      perform_enqueued_jobs do
        assert_turbo_stream_broadcasts([ @pin.user, :pins_tray ], &block)
      end
    end
end
