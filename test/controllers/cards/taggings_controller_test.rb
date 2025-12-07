require "test_helper"

class Cards::TaggingsControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    account = Current.account
    kevin_identity = create(:identity, :kevin)
    kevin = create(:user, :kevin, account: account, identity: kevin_identity)
    create(:user, :system, account: account)
    board = create(:board, :writebook, account: account, creator: kevin)
    column = create(:column, :writebook_triage, board: board, account: account)

    card = with_current_user(kevin) do
      create(:card, :logo, board: board, column: column, account: account, creator: kevin)
    end

    sign_in_as kevin

    get new_card_tagging_path(card)
    assert_response :success
  end

  test "toggle tag on" do
    account = Current.account
    kevin_identity = create(:identity, :kevin)
    kevin = create(:user, :kevin, account: account, identity: kevin_identity)
    create(:user, :system, account: account)
    board = create(:board, :writebook, account: account, creator: kevin)
    column = create(:column, :writebook_triage, board: board, account: account)
    mobile_tag = create(:tag, :mobile, account: account)

    card = with_current_user(kevin) do
      create(:card, :logo, board: board, column: column, account: account, creator: kevin)
    end

    sign_in_as kevin

    assert_changes -> { card.tagged_with?(mobile_tag) }, from: false, to: true do
      post card_taggings_path(card), params: { tag_title: mobile_tag.title }, as: :turbo_stream
      assert_turbo_stream action: :replace, target: dom_id(card, :tags)
    end
  end

  test "toggle tag off" do
    account = Current.account
    kevin_identity = create(:identity, :kevin)
    kevin = create(:user, :kevin, account: account, identity: kevin_identity)
    create(:user, :system, account: account)
    board = create(:board, :writebook, account: account, creator: kevin)
    column = create(:column, :writebook_triage, board: board, account: account)
    web_tag = create(:tag, :web, account: account)

    card = with_current_user(kevin) do
      create(:card, :logo, board: board, column: column, account: account, creator: kevin)
    end

    create(:tagging, card: card, tag: web_tag, account: account)

    sign_in_as kevin

    assert_changes -> { card.tagged_with?(web_tag) }, from: true, to: false do
      post card_taggings_path(card), params: { tag_title: web_tag.title }, as: :turbo_stream
      assert_turbo_stream action: :replace, target: dom_id(card, :tags)
    end
  end
end
