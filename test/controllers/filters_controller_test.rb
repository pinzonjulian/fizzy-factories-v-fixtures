require "test_helper"

class FiltersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    @jz_identity = create(:identity, :jz)
    @jz = create(:user, :jz, account: @account, identity: @jz_identity)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @mobile_tag = create(:tag, :mobile, account: @account)

    sign_in_as @david
  end

  test "create" do
    assert_difference "@david.filters.count", +1 do
      post filters_path, params: {
        indexed_by: "closed",
        assignment_status: "unassigned",
        tag_ids: [ @mobile_tag.id ],
        assignee_ids: [ @jz.id ],
        board_ids: [ @board.id ] }, as: :turbo_stream
    end
    assert_response :success

    filter = Filter.last
    assert_predicate filter.indexed_by, :closed?
    assert_predicate filter.assignment_status, :unassigned?
    assert_equal [ @mobile_tag ], filter.tags
    assert_equal [ @jz ], filter.assignees
    assert_equal [ @board ], filter.boards
  end

  test "destroy" do
    filter = create(:filter, creator: @david, account: @account, boards: [ @board ])
    expected_params = filter.as_params

    assert_difference "@david.filters.count", -1 do
      delete filter_path(filter), as: :turbo_stream
    end
    assert_response :success
  end
end
