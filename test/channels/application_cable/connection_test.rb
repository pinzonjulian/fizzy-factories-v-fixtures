require "test_helper"

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    test "connects with valid session and account info" do
      account = create(:account, :initech)
      identity = create(:identity, :mike)
      mike = create(:user, :mike, account: account, identity: identity)
      session = create(:session, :mike, identity: identity)

      cookies.signed[:session_token] = session.signed_id

      connect "/cable", env: { "fizzy.external_account_id" => account.external_account_id }

      assert_equal mike, connection.current_user
      assert_equal account, Current.account
    end

    test "rejects with invalid session token" do
      account = create(:account, :initech)

      cookies.signed[:session_token] = "invalid-session-id"

      assert_reject_connection do
        connect "/cable", env: { "fizzy.external_account_id" => account.external_account_id }
      end
    end

    test "rejects when account does not exist" do
      identity = create(:identity, :mike)
      session = create(:session, :mike, identity: identity)

      cookies.signed[:session_token] = session.signed_id

      assert_reject_connection do
        connect "/cable", env: { "fizzy.external_account_id" => -1 }
      end
    end
  end
end
