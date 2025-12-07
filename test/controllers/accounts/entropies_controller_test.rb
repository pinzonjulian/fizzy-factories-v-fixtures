require "test_helper"

class Account::EntropiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    integration_session.default_url_options[:script_name] = Current.account.slug
  end

  test "update" do
    account = Current.account
    kevin = create(:user, :kevin, account: account)
    account.create_entropy!(auto_postpone_period: 30.days) unless account.entropy

    sign_in_as kevin

    put account_entropy_path, params: { entropy: { auto_postpone_period: 1.day } }

    assert_equal 1.day, account.entropy.reload.auto_postpone_period

    assert_redirected_to account_settings_path
  end

  test "update requires admin" do
    account = Current.account
    david = create(:user, :david, account: account)
    account.create_entropy!(auto_postpone_period: 30.days) unless account.entropy

    sign_in_as david

    put account_entropy_path, params: { entropy: { auto_postpone_period: 1.day } }
    assert_response :forbidden
  end
end
