require "test_helper"

class Notifier::EventNotifierTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    @jz_identity = create(:identity, :jz)
    @kevin_identity = create(:identity, :kevin)
    Current.session = create(:session, identity: @david_identity)
    @system_user = create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @jz = create(:user, :jz, account: @account, identity: @jz_identity)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)
    @column = create(:column, :writebook_triage, board: @board, account: @account)

    @logo_card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end

    @layout_card = with_current_user(@david) do
      create(:card, :layout, board: @board, column: @column, account: @account, creator: @david)
    end
  end

  test "for returns the matching notifier class for the event" do
    event = create(:event, action: "card_published", account: @account, creator: @david, board: @board, eventable: @logo_card)

    assert_kind_of Notifier::CardEventNotifier, Notifier.for(event)
  end

  test "generate does not create notifications if the event was system-generated" do
    @logo_card.drafted!
    event = create(:event, action: "card_published", account: @account, creator: @system_user, board: @board, eventable: @logo_card)

    assert_no_difference -> { Notification.count } do
      Notifier.for(event).notify
    end
  end

  test "creates a notification for each watcher, other than the event creator (events)" do
    create(:watch, account: @account, card: @layout_card, user: @kevin, watching: true)
    comment = with_current_user(@david) do
      @layout_card.comments.create!(creator: @david, account: @account)
    end
    event = create(:event, action: "comment_created", account: @account, creator: @david, board: @board, eventable: comment)

    notifications = Notifier.for(event).notify

    assert_equal [ @kevin ], notifications.map(&:user)
  end

  test "creates a notification for each watcher (mentions)" do
    create(:watch, account: @account, card: @layout_card, user: @kevin, watching: true)
    comment = with_current_user(@david) do
      @layout_card.comments.create!(creator: @david, account: @account)
    end
    event = create(:event, action: "comment_created", account: @account, creator: @david, board: @board, eventable: comment)

    notifications = Notifier.for(event).notify

    assert_equal [ @kevin ], notifications.map(&:user)
  end

  test "does not create a notification for access-only users" do
    @board.access_for(@kevin).access_only!
    create(:watch, account: @account, card: @layout_card, user: @kevin, watching: true)
    comment = with_current_user(@david) do
      @layout_card.comments.create!(creator: @david, account: @account)
    end
    event = create(:event, action: "comment_created", account: @account, creator: @david, board: @board, eventable: comment)

    notifications = Notifier.for(event).notify

    assert_equal [ @kevin ], notifications.map(&:user)
  end

  test "links to the card" do
    @board.access_for(@kevin).watching!
    event = create(:event, action: "card_published", account: @account, creator: @david, board: @board, eventable: @logo_card)

    Notifier.for(event).notify

    assert_equal @logo_card, Notification.last.source.eventable
  end

  test "assignment events only create a notification for the assignee" do
    @board.access_for(@jz).watching!
    @board.access_for(@kevin).watching!
    event = create(:event, action: "card_assigned", account: @account, creator: @david, board: @board, eventable: @logo_card)
    event.assignee_ids = [ @jz.id ]
    event.save!
    event = Event.find(event.id)

    notifications = Notifier.for(event).notify

    assert_equal [ @jz ], notifications.map(&:user)
  end

  test "assignment events do not notify users who are access-only for the board" do
    @board.access_for(@jz).watching!
    event = create(:event, action: "card_assigned", account: @account, creator: @jz, board: @board, eventable: @logo_card)
    event.assignee_ids = [ @jz.id ]
    event.save!
    event = Event.find(event.id)

    notifications = Notifier.for(event).notify

    assert_empty notifications
  end

  test "assignment events do not notify you if you assigned yourself" do
    @board.access_for(@david).watching!
    event = create(:event, action: "card_assigned", account: @account, creator: @david, board: @board, eventable: @logo_card)
    event.assignee_ids = [ @david.id ]
    event.save!
    event = Event.find(event.id)

    notifications = Notifier.for(event).notify

    assert_empty notifications
  end

  test "create notifications on publish for mentionees" do
    create(:assignment, account: @account, card: @logo_card, assignee: @kevin, assigner: @david)
    @kevin.mentioned_by(@david, at: @logo_card)
    event = create(:event, action: "card_published", account: @account, creator: @david, board: @board, eventable: @logo_card)

    assert_difference -> { @kevin.notifications.count }, +1 do
      Notifier.for(event).notify
    end
  end

  test "don'create notifications on publish for mentionees that are not watching" do
    create(:assignment, account: @account, card: @logo_card, assignee: @kevin, assigner: @david)
    @kevin.mentioned_by(@david, at: @logo_card)
    @logo_card.unwatch_by(@kevin)
    event = create(:event, action: "card_published", account: @account, creator: @david, board: @board, eventable: @logo_card)

    assert_difference -> { @kevin.notifications.count }, +1 do
      Notifier.for(event).notify
    end
  end

  test "don't create notifications on comment for mentionees" do
    @david.mentioned_by(@kevin, at: @layout_card)
    comment = with_current_user(@david) do
      @layout_card.comments.create!(creator: @david, account: @account)
    end
    event = create(:event, action: "comment_created", account: @account, creator: @david, board: @board, eventable: comment)

    assert_no_difference -> { @david.notifications.count } do
      Notifier.for(event).notify
    end
  end

  test "assignment events notify assignees regardless of involvement level" do
    @board.access_for(@jz).access_only!
    event = create(:event, action: "card_assigned", account: @account, creator: @david, board: @board, eventable: @logo_card)
    event.assignee_ids = [ @jz.id ]
    event.save!
    event = Event.find(event.id)

    notifications = Notifier.for(event).notify

    assert_equal [ @jz ], notifications.map(&:user)
  end
end
