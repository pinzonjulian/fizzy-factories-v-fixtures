require "test_helper"

class Cards::CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    kevin_identity = create(:identity, :kevin)
    jz_identity = create(:identity, :jz)
    david_identity = create(:identity, :david)
    @kevin = create(:user, :kevin, account: @account, identity: kevin_identity)
    @jz = create(:user, :jz, account: @account, identity: jz_identity)
    david = create(:user, :david, account: @account, identity: david_identity)
    @board = create(:board, :writebook, account: @account, creator: david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)

    with_current_user(david) do
      @card = create(:card, :logo, board: @board, column: @column, account: @account, creator: david)
    end

    sign_in_as @kevin
  end

  test "create" do
    assert_difference -> { @card.comments.count }, +1 do
      post card_comments_path(@card), params: { comment: { body: "Agreed." } }, as: :turbo_stream
    end

    assert_response :success
  end

  test "update" do
    comment_kevin = create(:comment, :logo_agreement_kevin, card: @card, creator: @kevin, account: @account)

    put card_comment_path(@card, comment_kevin), params: { comment: { body: "I've changed my mind" } }, as: :turbo_stream

    assert_response :success
    assert_action_text "I've changed my mind", comment_kevin.reload.body
  end

  test "update another user's comment" do
    comment_jz = create(:comment, :logo_agreement_jz, card: @card, creator: @jz, account: @account)

    assert_no_changes -> { comment_jz.reload.body.to_s } do
      put card_comment_path(@card, comment_jz), params: { comment: { body: "I've changed my mind" } }, as: :turbo_stream
    end

    assert_response :forbidden
  end
end
