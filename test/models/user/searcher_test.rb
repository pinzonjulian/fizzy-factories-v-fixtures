require "test_helper"

class User::SearcherTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @kevin_identity = create(:identity, :kevin)
    Current.session = create(:session, identity: @kevin_identity)
    create(:user, :system, account: @account)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)
  end

  test "remember the last search" do
    assert_difference -> { @kevin.search_queries.count }, +1 do
      @kevin.remember_search("broken")
    end

    assert_equal "broken", @kevin.search_queries.last.terms
  end

  test "don't duplicate repeated searches but touch the existing match" do
    search_result = @kevin.remember_search("broken")
    original_updated_at = search_result.updated_at

    travel_to 1.day.from_now

    assert_no_difference -> { @kevin.search_queries.count }, +1 do
      @kevin.remember_search("broken")
    end

    assert search_result.reload.updated_at > original_updated_at
  end
end
