require "test_helper"

class AccessTest < ActiveSupport::TestCase
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
  end

  test "acesssed" do
    freeze_time

    access = @board.access_for(@kevin)

    assert_changes -> { access.reload.accessed_at }, from: nil, to: Time.current do
      access.accessed
    end

    travel 2.minutes

    assert_no_changes -> { access.reload.accessed_at } do
      access.accessed
    end
  end

  test "event notifications are destroyed when access is lost" do
    card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end

    event = Event.create!(
      creator: @david,
      board: @board,
      eventable: card,
      action: "card_published",
      account: @account
    )
    notification_card = Notification.create!(
      user: @kevin,
      source: event,
      creator: @david,
      account: @account
    )

    comment = with_current_user(@david) do
      card.comments.create!(creator: @david)
    end
    comment_event = Event.create!(
      creator: @david,
      board: @board,
      eventable: comment,
      action: "comment_created",
      account: @account
    )
    notification_comment = Notification.create!(
      user: @kevin,
      source: comment_event,
      creator: @david,
      account: @account
    )

    assert @kevin.notifications.map(&:source).map(&:eventable_type).uniq.sort == [ "Card", "Comment" ]

    notifications_to_be_destroyed = @kevin.notifications.select do |notification|
      notification.card&.board == @board
    end
    assert notifications_to_be_destroyed.any?

    kevin_access = @board.access_for(@kevin)

    perform_enqueued_jobs only: Board::CleanInaccessibleDataJob do
      kevin_access.destroy
    end

    remaining_notifications = @kevin.notifications.reload.select do |notification|
      notification.card&.board == @board
    end

    assert_empty remaining_notifications
  end

  test "mentions are destroyed when access is lost" do
    card = with_current_user(@jz) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @jz)
    end

    Mention.create!(
      account: @account,
      source: card,
      mentioner: @jz,
      mentionee: @david
    )

    comment = with_current_user(@jz) do
      card.comments.create!(creator: @jz)
    end
    Mention.create!(
      account: @account,
      source: comment,
      mentioner: @jz,
      mentionee: @david
    )

    assert @david.mentions.map(&:source_type).uniq.sort == [ "Card", "Comment" ]

    mentions_to_be_destroyed = @david.mentions.select do |mention|
      mention.card&.board == @board
    end
    assert mentions_to_be_destroyed.any?

    david_access = @board.access_for(@david)

    perform_enqueued_jobs only: Board::CleanInaccessibleDataJob do
      david_access.destroy
    end

    remaining_mentions = @david.mentions.reload.select do |mention|
      mention.card&.board == @board
    end

    assert_empty remaining_mentions
  end

  test "watches are destroyed when access is lost" do
    card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end
    card.watch_by(@kevin)

    assert card.watched_by?(@kevin)

    kevin_access = @board.access_for(@kevin)

    perform_enqueued_jobs only: Board::CleanInaccessibleDataJob do
      kevin_access.destroy
    end

    assert_not card.watched_by?(@kevin)
  end
end
