require "test_helper"

class My::TimezonesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @kevin = create(:user, :kevin, account: @account)
    sign_in_as @kevin
  end

  test "update" do
    time_zone = ActiveSupport::TimeZone["America/New_York"]

    assert_not_equal time_zone, @kevin.timezone
    patch my_timezone_path, params: { timezone_name: "America/New_York" }
    assert_equal time_zone, @kevin.reload.timezone
  end
end
