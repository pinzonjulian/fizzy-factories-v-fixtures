require "test_helper"

class User::NotifiableTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)

    @card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end

    @event = create(:event, :logo_published, account: @account, creator: @david, board: @board, eventable: @card)

    @david.settings.bundle_email_every_few_hours!
  end

  test "bundle method creates new bundle for first notification" do
    notification = assert_difference -> { @david.notification_bundles.count }, 1 do
      @david.notifications.create!(source: @event, creator: @david)
    end

    bundle = @david.notification_bundles.last
    assert_equal notification.created_at, bundle.starts_at
    assert bundle.pending?
  end

  test "bundle method finds existing bundle within aggregation period" do
    @david.notifications.create!(source: @event, creator: @david)

    assert_no_difference -> { @david.notification_bundles.count } do
      @david.notifications.create!(source: @event, creator: @david)
    end
  end
end
