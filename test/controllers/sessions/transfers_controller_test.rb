require "test_helper"

class Sessions::TransfersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @david_identity = create(:identity, :david)
  end

  test "show renders when not signed in" do
    untenanted do
      get session_transfer_path("some-token")

      assert_response :success
    end
  end

  test "update establishes a session when the code is valid" do
    untenanted do
      put session_transfer_path(@david_identity.transfer_id)

      assert_redirected_to session_menu_url(script_name: nil)
      assert parsed_cookies.signed[:session_token]
    end
  end
end
