require "test_helper"

class Searches::QueriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @kevin_identity = create(:identity, :kevin)
    create(:session, identity: @kevin_identity)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)

    sign_in_as @kevin
  end

  test "create" do
    assert_difference -> { @kevin.search_queries.count }, +1 do
      post searches_queries_path, params: { q: "layout issues" }
    end

    assert_equal "layout issues", @kevin.search_queries.last.terms
    assert_response :success
  end
end
