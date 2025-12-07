require "test_helper"

class Card::StatusesTest < ActiveSupport::TestCase
  setup do
    @account = Current.account

    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    @kevin_identity = create(:identity, :kevin)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)

    @jz_identity = create(:identity, :jz)
    @jz = create(:user, :jz, account: @account, identity: @jz_identity)

    create(:user, :system, account: @account)

    @board = create(:board, :writebook, account: @account, creator: @david)
  end

  test "cards start out in a `drafted` state" do
    card = with_current_user(@kevin) do
      @board.cards.create! creator: @kevin, title: "Newly created card"
    end

    assert card.drafted?
  end

  test "cards are only visible to the creator when drafted" do
    card = with_current_user(@kevin) do
      @board.cards.create! creator: @kevin, title: "Drafted Card"
    end
    card.drafted!

    assert_includes Card.published_or_drafted_by(@kevin), card
    assert_not_includes Card.published_or_drafted_by(@jz), card
  end

  test "cards are visible to everyone when published" do
    card = with_current_user(@kevin) do
      @board.cards.create! creator: @kevin, title: "Published Card"
    end
    card.published!

    assert_includes Card.published_or_drafted_by(@kevin), card
    assert_includes Card.published_or_drafted_by(@jz), card
  end

  test "an event is created when a card is created in the published state" do
    assert_no_difference(-> { Event.count }) do
      with_current_user(@kevin) do
        @board.cards.create! creator: @kevin, title: "Draft Card"
      end
    end

    assert_difference(-> { Event.count } => +1) do
      with_current_user(@kevin) do
        @card = @board.cards.create! creator: @kevin, title: "Published Card", status: :published
      end
    end

    event = Event.last
    assert_equal @card, event.eventable
    assert_equal "card_published", event.action
  end

  test "an event is created when a card is published" do
    card = with_current_user(@kevin) do
      @board.cards.create! creator: @kevin, title: "Published Card"
    end
    assert_difference(-> { Event.count } => +1) do
      card.publish
    end

    event = Event.last
    assert_equal card, event.eventable
    assert_equal "card_published", event.action
  end

  test "created_at is updated when the card is published" do
    freeze_time

    card = travel_to 1.week.ago do
      with_current_user(@kevin) do
        @board.cards.create! creator: @kevin, title: "Newly created card"
      end
    end

    assert card.drafted?
    assert_equal 1.week.ago, card.created_at

    card.publish

    assert_equal Time.current, card.created_at
  end

  test "detect drafts that were just published" do
    card = with_current_user(@kevin) do
      @board.cards.create! creator: @kevin, title: "Draft Card"
    end
    assert card.drafted?
    assert_not card.was_just_published?

    card.publish

    assert card.was_just_published?
    assert_not Card.find(card.id).was_just_published?
  end

  test "detect cards that were created and published" do
    card = with_current_user(@kevin) do
      @board.cards.create! creator: @kevin, title: "Published Card", status: :published
    end
    assert card.was_just_published?

    assert_not Card.find(card.id).was_just_published?
  end
end
