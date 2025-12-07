require "test_helper"

class Admin::StatsControllerTest < ActionDispatch::IntegrationTest
  test "staff can access stats" do
    account = Current.account
    david = create(:user, :david, account: account)

    sign_in_as david

    untenanted do
      get admin_stats_url
    end

    assert_response :success
  end

  test "non-staff cannot access stats" do
    account = Current.account
    jz = create(:user, :jz, account: account)

    sign_in_as jz

    untenanted do
      get admin_stats_url
    end

    assert_response :forbidden
  end
end
