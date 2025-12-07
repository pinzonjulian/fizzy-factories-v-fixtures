require "test_helper"

class Card::ReadableTest < ActiveSupport::TestCase
  setup do
    @account = Current.account

    @david_identity = create(:identity, :david)
    @kevin_identity = create(:identity, :kevin)
    @jz_identity = create(:identity, :jz)

    Current.session = create(:session, identity: @david_identity)

    @david = create(:user, :david, account: @account, identity: @david_identity)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)
    @jz = create(:user, :jz, account: @account, identity: @jz_identity)
    create(:user, :system, account: @account)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)

    @logo_card = with_current_user(@david) do
      create(:card, board: @board, column: @column, account: @account, creator: @david, title: "Logo card", status: "published")
    end

    @layout_card = with_current_user(@david) do
      create(:card, board: @board, column: @column, account: @account, creator: @david, title: "Layout card", status: "published")
    end
  end

  test "read clears events notifications" do
    logo_published_event = create_event(@logo_card, "card_published", @david)
    logo_assignment_event = create_event(@logo_card, "card_assigned", @david, { assignee_ids: [@kevin.id] })

    logo_published_notification = create(:notification, user: @kevin, source: logo_published_event, creator: @david, account: @account)
    logo_assignment_notification = create(:notification, user: @kevin, source: logo_assignment_event, creator: @david, account: @account)

    assert_changes -> { logo_published_notification.reload.read? }, from: false, to: true do
      assert_changes -> { logo_assignment_notification.reload.read? }, from: false, to: true do
        @logo_card.read_by(@kevin)
      end
    end
  end

  test "read clear mentions in the description" do
    mention = Mention.create!(account: @account, source: @logo_card, mentioner: @jz, mentionee: @david)
    mention_notification = create(:notification, user: @david, source: mention, creator: @jz, account: @account)

    assert_changes -> { mention_notification.reload.read? }, from: false, to: true do
      @logo_card.read_by(@david)
    end
  end

  test "read clear mentions in comments" do
    comment = with_current_user(@jz) do
      Comment.create!(card: @logo_card, creator: @jz, account: @account)
    end
    mention = Mention.create!(account: @account, source: comment, mentioner: @jz, mentionee: @david)
    mention_notification = create(:notification, user: @david, source: mention, creator: @jz, account: @account)

    assert_changes -> { mention_notification.reload.read? }, from: false, to: true do
      @logo_card.read_by(@david)
    end
  end

  test "read clears notifications from the comments" do
    comment = with_current_user(@david) do
      Comment.create!(card: @layout_card, creator: @david, account: @account)
    end
    comment_event = Event.create!(
      creator: @david,
      board: @board,
      eventable: comment,
      action: "comment_created",
      account: @account
    )
    comment_notification = create(:notification, user: @kevin, source: comment_event, creator: @david, account: @account)

    assert_changes -> { comment_notification.reload.read? }, from: false, to: true do
      @layout_card.read_by(@kevin)
    end
  end

  test "unread marks events notifications as unread" do
    logo_published_event = create_event(@logo_card, "card_published", @david)
    logo_assignment_event = create_event(@logo_card, "card_assigned", @david, { assignee_ids: [@kevin.id] })

    logo_published_notification = create(:notification, user: @kevin, source: logo_published_event, creator: @david, account: @account)
    logo_assignment_notification = create(:notification, user: @kevin, source: logo_assignment_event, creator: @david, account: @account)

    logo_published_notification.read
    logo_assignment_notification.read

    assert_changes -> { logo_published_notification.reload.read? }, from: true, to: false do
      assert_changes -> { logo_assignment_notification.reload.read? }, from: true, to: false do
        @logo_card.unread_by(@kevin)
      end
    end
  end

  test "unread marks mentions in the description as unread" do
    mention = Mention.create!(account: @account, source: @logo_card, mentioner: @jz, mentionee: @david)
    mention_notification = create(:notification, user: @david, source: mention, creator: @jz, account: @account)
    mention_notification.read

    assert_changes -> { mention_notification.reload.read? }, from: true, to: false do
      @logo_card.unread_by(@david)
    end
  end

  test "unread marks mentions in comments as unread" do
    comment = with_current_user(@jz) do
      Comment.create!(card: @logo_card, creator: @jz, account: @account)
    end
    mention = Mention.create!(account: @account, source: comment, mentioner: @jz, mentionee: @david)
    mention_notification = create(:notification, user: @david, source: mention, creator: @jz, account: @account)
    mention_notification.read

    assert_changes -> { mention_notification.reload.read? }, from: true, to: false do
      @logo_card.unread_by(@david)
    end
  end

  test "unread marks notifications from the comments as unread" do
    comment = with_current_user(@david) do
      Comment.create!(card: @layout_card, creator: @david, account: @account)
    end
    comment_event = Event.create!(
      creator: @david,
      board: @board,
      eventable: comment,
      action: "comment_created",
      account: @account
    )
    comment_notification = create(:notification, user: @kevin, source: comment_event, creator: @david, account: @account)
    comment_notification.read

    assert_changes -> { comment_notification.reload.read? }, from: true, to: false do
      @layout_card.unread_by(@kevin)
    end
  end

  test "remove inaccessible notifications" do
    private_board = create(:board, account: @account, creator: @kevin, all_access: false, name: "Test Private Board")
    private_column = create(:column, :writebook_triage, board: private_board, account: @account)

    create(:access, account: @account, board: private_board, user: @david)
    create(:access, account: @account, board: private_board, user: @jz)

    card = with_current_user(@david) do
      create(:card, board: private_board, column: private_column, account: @account, creator: @david, title: "Test card", status: "published")
    end

    logo_published_event = Event.create!(creator: @david, board: private_board, eventable: card, action: "card_published", account: @account)
    logo_assignment_event = Event.create!(creator: @david, board: private_board, eventable: card, action: "card_assigned", particulars: { assignee_ids: [@kevin.id] }.to_json, account: @account)

    kevin_notifications = [
      create(:notification, user: @kevin, source: logo_published_event, creator: @david, account: @account),
      create(:notification, user: @kevin, source: logo_assignment_event, creator: @david, account: @account)
    ]

    card_mention = Mention.create!(account: @account, source: card, mentioner: @jz, mentionee: @david)
    comment = with_current_user(@jz) do
      Comment.create!(card: card, creator: @jz, account: @account)
    end
    comment_mention = Mention.create!(account: @account, source: comment, mentioner: @jz, mentionee: @david)

    david_notifications = [
      create(:notification, user: @david, source: card_mention, creator: @jz, account: @account),
      create(:notification, user: @david, source: comment_mention, creator: @jz, account: @account)
    ]

    assert card.accessible_to?(@kevin)

    private_board.accesses.find_by(user: @kevin).destroy
    assert_not card.accessible_to?(@kevin)
    assert card.accessible_to?(@david)

    card.remove_inaccessible_notifications

    kevin_notifications.each do |notification|
      assert_not Notification.exists?(notification.id)
    end

    david_notifications.each do |notification|
      assert Notification.exists?(notification.id)
    end
  end

  private

  def create_event(card, action, creator, particulars = {})
    Event.create!(
      creator: creator,
      board: @board,
      eventable: card,
      action: action,
      particulars: particulars.to_json,
      account: @account
    )
  end
end
