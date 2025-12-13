require "test_helper"

class Users::PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :david
  end

  test "create new push subscription" do
    subscription_params = { "endpoint" => "https://apple", "p256dh_key" => "123", "auth_key" => "456" }

    post user_push_subscriptions_path(users.david),
      params: { push_subscription: subscription_params }, headers: { "HTTP_USER_AGENT" => "Mozilla/5.0" }

    assert_response :ok

    assert_equal subscription_params, users.david.push_subscriptions.last.attributes.slice("endpoint", "p256dh_key", "auth_key")
    assert_equal "Mozilla/5.0", users.david.push_subscriptions.last.user_agent
  end

  test "touch existing subscription" do
    existing_subscription = users.david.push_subscriptions.create!(
      endpoint: "https://apple",
      p256dh_key: "123",
      auth_key: "456"
    )

    assert_no_difference -> { users.david.push_subscriptions.count } do
      assert_changes -> { existing_subscription.reload.updated_at } do
        post user_push_subscriptions_path(users.david), params: {
          push_subscription: existing_subscription.attributes.slice("endpoint", "p256dh_key", "auth_key")
        }
      end
    end

    assert_response :ok
  end

  test "destroy a push subscription" do
    subscription = users.david.push_subscriptions.create!(
      endpoint: "https://apple",
      p256dh_key: "123",
      auth_key: "456"
    )

    assert_difference -> { Push::Subscription.count }, -1 do
      delete user_push_subscription_path(users.david, subscription)
      assert_redirected_to user_push_subscriptions_path(users.david)
    end
  end
end
