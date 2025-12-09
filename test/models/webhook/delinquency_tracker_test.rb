require "test_helper"

class Webhook::DelinquencyTrackerTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    create(:user, :system, account: @account)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)

    @card = with_current_user(@david) do
      create(:card, :layout, board: @board, column: @column, account: @account, creator: @david)
    end

    @comment = with_current_user(@david) do
      Comment.create!(card: @card, creator: @david, account: @account, body: "Test comment")
    end

    @event = Event.create!(
      creator: @david,
      board: @board,
      eventable: @comment,
      action: "comment_created",
      account: @account
    )

    @webhook = create(:webhook, :active, board: @board, account: @account)
    @tracker = @webhook.delinquency_tracker

    @successful_delivery = Webhook::Delivery.create!(
      webhook: @webhook,
      event: @event,
      state: "completed",
      response: { code: 200 }
    )

    @failed_delivery = Webhook::Delivery.create!(
      webhook: @webhook,
      event: @event,
      state: "errored",
      response: { code: 500 }
    )
  end

  test "record_delivery_of" do
    @tracker.update!(consecutive_failures_count: 5)
    @tracker.record_delivery_of(@successful_delivery)
    @tracker.reload

    assert_equal 0, @tracker.consecutive_failures_count
    assert_nil @tracker.first_failure_at

    assert_difference -> { @tracker.reload.consecutive_failures_count }, +1 do
      @tracker.record_delivery_of(@failed_delivery)
    end

    @tracker.reload
    assert_not_nil @tracker.first_failure_at

    assert_difference -> { @tracker.reload.consecutive_failures_count }, +1 do
      assert_no_difference -> { @tracker.reload.first_failure_at } do
        @tracker.record_delivery_of(@failed_delivery)
      end
    end

    travel_to 2.hours.from_now do
      @tracker.update!(consecutive_failures_count: 9)
      @webhook.activate

      assert_changes -> { @webhook.reload.active? }, from: true, to: false do
        @tracker.record_delivery_of(@failed_delivery)
      end
    end
  end
end
