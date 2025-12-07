require "test_helper"

class Card::ActivitySpike::DetectorTest < ActiveSupport::TestCase
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

    @card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end

    @shipping = with_current_user(@kevin) do
      create(:card, :shipping, board: @board, column: @column, account: @account, creator: @kevin)
    end
  end

  test "detect multiple people commenting" do
    assert_activity_spike_detected do
      multiple_people_comment_on(@card, people: [@david, @kevin, @jz])
    end
  end

  test "detect assignments" do
    assert_activity_spike_detected do
      @card.toggle_assignment @kevin
    end
  end

  test "detect reopened cards" do
    @shipping.close
    assert_activity_spike_detected(card: @shipping) do
      @shipping.reopen
    end
  end

  test "refresh the activity spike on new spikes" do
    multiple_people_comment_on(@card, people: [@david, @kevin, @jz])

    @card = Card.find(@card.id)

    original_last_spike_at = @card.activity_spike.updated_at
    travel 2.months

    multiple_people_comment_on(@card.reload, people: [@david, @kevin, @jz])

    assert @card.reload.activity_spike.updated_at > original_last_spike_at
  end

  test "concurrent spike creation should not create multiple spikes for a card" do
    multiple_people_comment_on(@card, people: [@david, @kevin, @jz])
    @card.activity_spike&.destroy

    5.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Card.find(@card.id).detect_activity_spikes
        end
      end
    end.each(&:join)

    assert_equal 1, Card::ActivitySpike.where(card: @card).count
  end

  private
    def assert_activity_spike_detected(card: @card)
      assert card.activity_spike.blank?
      perform_enqueued_jobs only: Card::ActivitySpike::DetectionJob do
        yield
      end
      assert card.reload.activity_spike.present?
    end
end
