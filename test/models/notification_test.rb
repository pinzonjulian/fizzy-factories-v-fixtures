require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  setup do
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @account = Current.account

    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    @kevin_identity = create(:identity, :kevin)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)

    @card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end

    @event = Event.create!(
      creator: @david,
      board: @board,
      eventable: @card,
      action: "card_published",
      account: @account
    )

    @notification = Notification.create!(
      user: @kevin,
      source: @event,
      creator: @david,
      account: @account
    )
  end

  test "unread marks notification as unread" do
    @notification.read

    assert_changes -> { @notification.reload.read? }, from: true, to: false do
      @notification.unread
    end
  end

  test "unread broadcasts to notifications" do
    @notification.read

    assert_turbo_stream_broadcasts([ @notification.user, :notifications ], count: 1) do
      @notification.unread
    end
  end

  test "read marks notification as read" do
    @notification.update!(read_at: nil)

    assert_changes -> { @notification.reload.read? }, from: false, to: true do
      @notification.read
    end
  end

  test "read broadcasts to notifications" do
    @notification.update!(read_at: nil)

    assert_turbo_stream_broadcasts([ @notification.user, :notifications ], count: 1) do
      @notification.read
    end
  end

  test "deleting notification broadcasts its removal" do
    @notification.update!(read_at: nil)

    assert_turbo_stream_broadcasts([ @notification.user, :notifications ], count: 1) do
      @notification.destroy
    end
  end
end
