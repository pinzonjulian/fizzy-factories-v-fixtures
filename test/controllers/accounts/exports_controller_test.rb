require "test_helper"

class Account::ExportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    integration_session.default_url_options[:script_name] = @account.slug
    @david = create(:user, :david, account: @account)
    sign_in_as @david
  end

  test "create creates an export record and enqueues job" do
    assert_difference -> { Account::Export.count }, 1 do
      assert_enqueued_with(job: ExportAccountDataJob) do
        post account_exports_path
      end
    end

    assert_redirected_to account_settings_path
    assert_equal "Export started. You'll receive an email when it's ready.", flash[:notice]
  end

  test "create associates export with current user" do
    post account_exports_path

    export = Account::Export.last
    assert_equal @david, export.user
    assert_equal Current.account, export.account
    assert export.pending?
  end

  test "create rejects request when current export limit is reached" do
    Account::ExportsController::CURRENT_EXPORT_LIMIT.times do
      Account::Export.create!(account: @account, user: @david)
    end

    assert_no_difference -> { Account::Export.count } do
      post account_exports_path
    end

    assert_response :too_many_requests
  end

  test "create allows request when exports are older than one day" do
    Account::ExportsController::CURRENT_EXPORT_LIMIT.times do
      Account::Export.create!(account: @account, user: @david, created_at: 2.days.ago)
    end

    assert_difference -> { Account::Export.count }, 1 do
      post account_exports_path
    end

    assert_redirected_to account_settings_path
  end

  test "show displays completed export with download link" do
    export = Account::Export.create!(account: @account, user: @david)
    export.build

    get account_export_path(export)

    assert_response :success
    assert_select "a#download-link"
  end

  test "show displays a warning if the export is missing" do
    get account_export_path("not-really-an-export")

    assert_response :success
    assert_select "h2", "Download Expired"
  end

  test "show does not allow access to another user's export" do
    kevin = create(:user, :kevin, account: @account)
    export = Account::Export.create!(account: @account, user: kevin)
    export.build

    get account_export_path(export)

    assert_response :success
    assert_select "h2", "Download Expired"
  end
end
