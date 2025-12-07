require "test_helper"

class Cards::Comments::ReactionsControllerTest < ActionDispatch::IntegrationTest
  test "create" do
    account = Current.account
    david_identity = create(:identity, :david)
    Current.session = create(:session, identity: david_identity)
    david = create(:user, :david, account: account, identity: david_identity)
    jz_identity = create(:identity, :jz)
    jz = create(:user, :jz, account: account, identity: jz_identity)
    create(:user, :system, account: account)
    board = create(:board, :writebook, account: account, creator: david)
    column = create(:column, :writebook_triage, board: board, account: account)
    card = with_current_user(david) do
      create(:card, :logo, board: board, column: column, account: account, creator: david)
    end
    comment = create(:comment, card: card, creator: jz, account: account)

    sign_in_as david

    assert_difference -> { comment.reactions.count }, 1 do
      post card_comment_reactions_path(card, comment, format: :turbo_stream), params: { reaction: { content: "Great work!" } }
      assert_turbo_stream action: :replace, target: dom_id(comment, :reacting)
    end
  end

  test "destroy" do
    account = Current.account
    david_identity = create(:identity, :david)
    Current.session = create(:session, identity: david_identity)
    david = create(:user, :david, account: account, identity: david_identity)
    jz_identity = create(:identity, :jz)
    jz = create(:user, :jz, account: account, identity: jz_identity)
    create(:user, :system, account: account)
    board = create(:board, :writebook, account: account, creator: david)
    column = create(:column, :writebook_triage, board: board, account: account)
    card = with_current_user(david) do
      create(:card, :logo, board: board, column: column, account: account, creator: david)
    end
    comment = create(:comment, card: card, creator: jz, account: account)
    reaction = create(:reaction, comment: comment, reacter: david, content: "👍", account: account)

    sign_in_as david

    assert_difference -> { comment.reactions.count }, -1 do
      delete card_comment_reaction_path(card, comment, reaction, format: :turbo_stream)
      assert_turbo_stream action: :remove, target: dom_id(reaction)
    end
  end

  test "non-owner cannot destroy reaction" do
    account = Current.account
    david_identity = create(:identity, :david)
    Current.session = create(:session, identity: david_identity)
    david = create(:user, :david, account: account, identity: david_identity)
    jz_identity = create(:identity, :jz)
    jz = create(:user, :jz, account: account, identity: jz_identity)
    kevin_identity = create(:identity, :kevin)
    kevin = create(:user, :kevin, account: account, identity: kevin_identity)
    create(:user, :system, account: account)
    board = create(:board, :writebook, account: account, creator: david)
    column = create(:column, :writebook_triage, board: board, account: account)
    card = with_current_user(david) do
      create(:card, :logo, board: board, column: column, account: account, creator: david)
    end
    comment = create(:comment, card: card, creator: jz, account: account)
    reaction = create(:reaction, comment: comment, reacter: kevin, content: "👍", account: account)

    sign_in_as david

    assert_no_difference -> { comment.reactions.count } do
      delete card_comment_reaction_path(card, comment, reaction, format: :turbo_stream)
      assert_response :forbidden
    end
  end
end
