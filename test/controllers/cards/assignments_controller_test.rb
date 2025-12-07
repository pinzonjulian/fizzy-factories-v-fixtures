require "test_helper"

class Cards::AssignmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @kevin_identity = create(:identity, :kevin)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)
    create(:user, :system, account: @account)
    @board = create(:board, :writebook, account: @account, creator: @kevin)
    @column = create(:column, :writebook_triage, board: @board, account: @account)
  end

  test "new" do
    card = with_current_user(@kevin) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @kevin)
    end

    sign_in_as @kevin

    get new_card_assignment_path(card)
    assert_response :success
  end

  test "create" do
    david_identity = create(:identity, :david)
    david = create(:user, :david, account: @account, identity: david_identity)

    card = with_current_user(@kevin) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @kevin)
    end

    sign_in_as @kevin

    assert_changes -> { card.reload.assigned_to?(david) }, from: false, to: true do
      post card_assignments_path(card), params: { assignee_id: david.id }, as: :turbo_stream
      assert_meta_replaced(card)
    end

    assert_changes -> { card.reload.assigned_to?(david) }, from: true, to: false do
      post card_assignments_path(card), params: { assignee_id: david.id }, as: :turbo_stream
      assert_meta_replaced(card)
    end
  end

  private
    def assert_meta_replaced(card)
      assert_turbo_stream action: :replace, target: dom_id(card, :meta)
    end
end
