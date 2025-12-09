require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @kevin_identity = create(:identity, :kevin)
    @kevin_session = create(:session, identity: @kevin_identity)
  end

  test "new" do
    untenanted do
      get new_session_path
    end

    assert_response :success
  end

  test "create" do
    untenanted do
      assert_difference -> { MagicLink.count }, 1 do
        post session_path, params: { email_address: @kevin_identity.email_address }
      end

      assert_redirected_to session_magic_link_path
      assert_nil flash[:magic_link_code]
    end
  end

  test "create for a new user" do
    untenanted do
      assert_difference -> { MagicLink.count }, +1 do
        assert_difference -> { Identity.count }, +1 do
          post session_path,
            params: { email_address: "nonexistent-#{SecureRandom.hex(6)}@example.com" }
        end
      end

      assert_redirected_to session_magic_link_path
      assert MagicLink.last.for_sign_up?
    end
  end

  test "create with invalid email address" do
    without_action_dispatch_exception_handling do
      untenanted do
        assert_no_difference -> { Identity.count } do
          post session_path, params: { email_address: "not-a-valid-email" }
        end

        assert_response :unprocessable_entity
      end
    end
  end

  test "destroy" do
    sign_in_as @kevin_identity

    untenanted do
      delete session_path

      assert_redirected_to new_session_path
      assert_not cookies[:session_token].present?
    end
  end
end
