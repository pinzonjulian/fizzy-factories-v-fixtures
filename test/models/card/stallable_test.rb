require "test_helper"

class Card::StallableTest < ActiveSupport::TestCase
  include CardActivityTestHelper

  setup do
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @account = Current.account

    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    @kevin_identity = create(:identity, :kevin)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)

    @jz_identity = create(:identity, :jz)
    @jz = create(:user, :jz, account: @account, identity: @jz_identity)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)
    create(:entropy, container: @board, account: @account, auto_postpone_period: 90.days.to_i)

    @logo = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end
  end

  test "a card without activity spike is not stalled" do
    assert_not @logo.stalled?
    assert_not_includes Card.stalled, @logo
  end

  test "a card with a recent activity spike is not stalled" do
    @logo.create_activity_spike!

    assert_not @logo.stalled?
    assert_not_includes Card.stalled, @logo
  end

  test "a card with an old activity spike is stalled" do
    @logo.create_activity_spike!

    travel_to 3.months.from_now

    assert @logo.stalled?
    assert_includes Card.stalled, @logo
  end

  test "a stalled card can be unstalled with a single comment" do
    @logo.create_activity_spike!

    travel_to 3.months.from_now

    assert @logo.stalled?
    assert_includes Card.stalled, @logo

    @logo.comments.create!(body: "A new comment to unstall the card")

    assert_not @logo.stalled?
    assert_not_includes Card.stalled, @logo

    # and stalls again after more time passes
    travel_to 3.months.from_now

    assert @logo.stalled?
    assert_includes Card.stalled, @logo
  end

  test "a card with an old activity spike is not stalled after being postponed" do
    @logo.create_activity_spike!

    travel_to 3.months.from_now

    assert @logo.stalled?
    assert_includes Card.stalled, @logo

    travel_to Time.now + @logo.board.entropy.auto_postpone_period + 1.day
    assert_includes Card.due_to_be_postponed, @logo

    Card.auto_postpone_all_due

    assert_not @logo.reload.stalled?
    assert_not_includes Card.stalled, @logo
  end

  # More fine-grained testing in Card::ActivitySpike::Detector
  test "detect activity spikes" do
    assert_not @logo.stalled?
    multiple_people_comment_on(@logo, people: [@david, @kevin, @jz])

    travel_to 1.month.from_now
    assert @logo.reload.stalled?
    assert_includes Card.stalled, @logo
  end

  test "don't detect activity spikes when updating attributes other than last_active_at" do
    assert_no_enqueued_jobs only: Card::ActivitySpike::DetectionJob do
      @logo.update! created_at: 1.day.ago
    end
  end

  test "don't detect activity spikes when creating new cards" do
    assert_no_enqueued_jobs only: Card::ActivitySpike::DetectionJob do
      @board.cards.create! title: "A new card", creator: @kevin
    end
  end
end
