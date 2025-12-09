require "test_helper"

class Sessions::MagicLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @kevin_identity = create(:identity, :kevin)
  end

  test "show" do
    untenanted do
      get session_magic_link_url

      assert_response :success
    end
  end

  test "create with sign in code" do
    magic_link = MagicLink.create!(identity: @kevin_identity)

    untenanted do
      post session_magic_link_url, params: { code: magic_link.code }

      assert_response :redirect
      assert cookies[:session_token].present?
      assert_redirected_to landing_path, "Should redirect to after authentication path"
      assert_not MagicLink.exists?(magic_link.id), "The magic link should be consumed"
    end
  end

  test "create with sign up code" do
    magic_link = MagicLink.create!(identity: @kevin_identity, purpose: :sign_up)

    untenanted do
      post session_magic_link_url, params: { code: magic_link.code }

      assert_response :redirect
      assert cookies[:session_token].present?
      assert_redirected_to new_signup_completion_path, "Should redirect to signup completion"
      assert_not MagicLink.exists?(magic_link.id), "The magic link should be consumed"
    end
  end

  test "create with invalid code" do
    magic_link = MagicLink.create!(identity: @kevin_identity)

    untenanted do
      post session_magic_link_url, params: { code: "INVALID" }
    end

    assert_response :redirect, "Invalid code should redirect"

    expired_link = MagicLink.create!(identity: @kevin_identity)
    expired_link.update_column(:expires_at, 1.hour.ago)

    post session_magic_link_url, params: { code: expired_link.code }

    assert_response :redirect, "Expired magic link should redirect"
    assert MagicLink.exists?(expired_link.id), "Expired magic link should not be consumed"
  end
end
