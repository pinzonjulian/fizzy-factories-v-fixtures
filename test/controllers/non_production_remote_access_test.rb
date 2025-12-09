require "test_helper"

class NonProductionRemoteAccessTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @david = create(:user, :david, account: @account)
    @jz = create(:user, :jz, account: @account)
  end

  test "staff can access in staging environment" do
    sign_in_as @david

    Rails.stubs(:env).returns(ActiveSupport::EnvironmentInquirer.new("staging"))
    get cards_path
    assert_response :success
  end

  test "non-staff cannot access in staging environment" do
    sign_in_as @jz

    Rails.stubs(:env).returns(ActiveSupport::EnvironmentInquirer.new("staging"))
    get cards_path
    assert_response :forbidden
  end

  test "non-staff can access in production environment" do
    sign_in_as @jz

    Rails.stubs(:env).returns(ActiveSupport::EnvironmentInquirer.new("production"))
    get cards_path
    assert_response :success
  end

  test "non-staff can access in local environment" do
    sign_in_as @jz

    get cards_path
    assert_response :success
  end
end
