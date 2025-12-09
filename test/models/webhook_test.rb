require "test_helper"

class WebhookTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @board = create(:board, :writebook, account: @account, creator: @david)
  end

  test "create" do
    webhook = Webhook.create! name: "Test", url: "https://example.com/webhook", board: @board
    assert webhook.persisted?
    assert webhook.active?
    assert webhook.signing_secret.present?
    assert webhook.delinquency_tracker.present?
  end

  test "validates the url" do
    webhook = Webhook.new name: "Test", board: @board
    assert_not webhook.valid?
    assert_includes webhook.errors[:url], "not a URL"

    webhook = Webhook.new name: "Test", board: @board, url: "not a url"
    assert_not webhook.valid?
    assert_includes webhook.errors[:url], "not a URL"

    webhook = Webhook.new name: "NOTHING", board: @board, url: "example.com/webhook"
    assert_not webhook.valid?
    assert_includes webhook.errors[:url], "must use http or https"

    webhook = Webhook.new name: "BLANK", board: @board, url: "//example.com/webhook"
    assert_not webhook.valid?
    assert_includes webhook.errors[:url], "must use http or https"

    webhook = Webhook.new name: "GOPHER", board: @board, url: "gopher://example.com/webhook"
    assert_not webhook.valid?
    assert_includes webhook.errors[:url], "must use http or https"

    webhook = Webhook.new name: "HTTP", board: @board, url: "http://example.com/webhook"
    assert webhook.valid?

    webhook = Webhook.new name: "HTTPS", board: @board, url: "https://example.com/webhook"
    assert webhook.valid?
  end

  test "deactivate" do
    webhook = create(:webhook, :active, board: @board, account: @account)

    assert_changes -> { webhook.active? }, from: true, to: false do
      webhook.deactivate
    end
  end

  test "activate" do
    webhook = create(:webhook, :inactive, board: @board, account: @account)

    assert_changes -> { webhook.active? }, from: false, to: true do
      webhook.activate
    end
  end

  test "for_slack?" do
    webhook = Webhook.new url: "https://hooks.slack.com/services/T12345678/B12345678/abc123xyz" # gitleaks:allow
    assert webhook.for_slack?

    webhook = Webhook.new url: "https://hooks.slack.com/services/T12345678/B12345678"
    assert_not webhook.for_slack?

    webhook = Webhook.new url: "https://hooks.slack.com/services/T12345678"
    assert_not webhook.for_slack?

    webhook = Webhook.new url: "https://hooks.slack.com/services/"
    assert_not webhook.for_slack?

    webhook = Webhook.new url: "https://example.com/webhook"
    assert_not webhook.for_slack?
  end

  test "for_campfire?" do
    webhook = Webhook.new url: "https://example.com/rooms/123/456-room-name/messages"
    assert webhook.for_campfire?

    webhook = Webhook.new url: "https://campfire.example.com/rooms/999/123-test-room/messages"
    assert webhook.for_campfire?

    webhook = Webhook.new url: "https://campfire.example.com/rooms/999/123/messages"
    assert_not webhook.for_campfire?, "The bot key is missing a token"

    webhook = Webhook.new url: "https://example.com/webhook"
    assert_not webhook.for_campfire?

    webhook = Webhook.new url: "https://example.com/rooms/123/messages"
    assert_not webhook.for_campfire?

    webhook = Webhook.new url: "https://example.com/rooms/123/456-room-name/"
    assert_not webhook.for_campfire?
  end

  test "for_basecamp?" do
    webhook = Webhook.new url: "https://basecamp.com/999/integrations/some-token/buckets/111/chats/222/lines"
    assert webhook.for_basecamp?

    webhook = Webhook.new url: "https://example.com/webhook"
    assert_not webhook.for_basecamp?

    webhook = Webhook.new url: "https://3.basecamp.com/123/integrations/webhook/buckets/456/chats/"
    assert_not webhook.for_basecamp?

    webhook = Webhook.new url: "https://3.basecamp.com/integrations/webhook/buckets/456/chats/789/lines"
    assert_not webhook.for_basecamp?
  end
end
