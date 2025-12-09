require "test_helper"

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @kevin = create(:user, :kevin, account: @account)
    @david = create(:user, :david, account: @account)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @private_board = create(:board, :private, account: @account, creator: @kevin)
    @active_webhook = create(:webhook, :active, board: @board, account: @account)
    @inactive_webhook = create(:webhook, :inactive, board: @private_board, account: @account)
    sign_in_as @kevin
  end

  test "index" do
    get board_webhooks_path(@board)
    assert_response :success
  end

  test "show" do
    get board_webhook_path(@active_webhook.board, @active_webhook)
    assert_response :success

    get board_webhook_path(@inactive_webhook.board, @inactive_webhook)
    assert_response :success
  end

  test "new" do
    get new_board_webhook_path(@board)
    assert_response :success
    assert_select "form"
  end

  test "create with valid params" do
    assert_difference "Webhook.count", 1 do
      post board_webhooks_path(@board), params: {
        webhook: {
          name: "Test Webhook",
          url: "https://example.com/webhook",
          subscribed_actions: [ "", "card_published", "card_closed" ]
        }
      }
    end

    webhook = Webhook.last

    assert_redirected_to board_webhook_path(webhook.board, webhook)
    assert_equal @board, webhook.board
    assert_equal "Test Webhook", webhook.name
    assert_equal "https://example.com/webhook", webhook.url
    assert_equal [ "card_published", "card_closed" ], webhook.subscribed_actions
  end

  test "create with invalid params" do
    assert_no_difference "Webhook.count" do
      post board_webhooks_path(@board), params: {
        webhook: {
          name: "",
          url: "invalid-url"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "edit" do
    get edit_board_webhook_path(@active_webhook.board, @active_webhook)
    assert_response :success
    assert_select "form"

    get edit_board_webhook_path(@inactive_webhook.board, @inactive_webhook)
    assert_response :success
    assert_select "form"
  end

  test "update with valid params" do
    patch board_webhook_path(@active_webhook.board, @active_webhook), params: {
      webhook: {
        name: "Updated Webhook",
        subscribed_actions: [ "card_published" ]
      }
    }

    @active_webhook.reload

    assert_redirected_to board_webhook_path(@active_webhook.board, @active_webhook)
    assert_equal "Updated Webhook", @active_webhook.name
    assert_equal [ "card_published" ], @active_webhook.subscribed_actions
  end

  test "update with invalid params" do
    patch board_webhook_path(@active_webhook.board, @active_webhook), params: {
      webhook: {
        name: ""
      }
    }

    assert_response :unprocessable_entity

    assert_no_changes -> { @active_webhook.reload.url } do
      patch board_webhook_path(@active_webhook.board, @active_webhook), params: {
        webhook: {
          name: "Updated Webhook",
          url: "https://different.com/webhook"
        }
      }
    end

    assert_redirected_to board_webhook_path(@active_webhook.board, @active_webhook)
  end

  test "destroy" do
    assert_difference "Webhook.count", -1 do
      delete board_webhook_path(@active_webhook.board, @active_webhook)
    end

    assert_redirected_to board_webhooks_path(@active_webhook.board)
  end
end
