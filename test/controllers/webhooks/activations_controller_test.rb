require "test_helper"

class Webhooks::ActivationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @kevin = create(:user, :kevin, account: @account)
    @private_board = create(:board, :private, account: @account, creator: @kevin)
    @inactive_webhook = create(:webhook, :inactive, board: @private_board, account: @account)
    sign_in_as @kevin
  end

  test "create" do
    assert_not @inactive_webhook.active?

    assert_changes -> { @inactive_webhook.reload.active? }, from: false, to: true do
      post board_webhook_activation_path(@inactive_webhook.board, @inactive_webhook)
    end

    assert_redirected_to board_webhook_path(@inactive_webhook.board, @inactive_webhook)
  end
end
