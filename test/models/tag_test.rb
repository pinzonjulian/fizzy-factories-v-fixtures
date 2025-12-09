require "test_helper"

class TagTest < ActiveSupport::TestCase
  setup do
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @account = Current.account

    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)
  end

  test "downcase title" do
    assert_equal "a tag", Tag.create!(title: "A TAG").title
  end

  test ".unused returns tags not associated with any cards" do
    web_tag = Tag.create!(title: "web", account: @account)
    mobile_tag = Tag.create!(title: "mobile", account: @account)
    unused_tag = Tag.create!(title: "unused", account: @account)

    card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end
    card.taggings.create!(tag: web_tag, account: @account)
    card.taggings.create!(tag: mobile_tag, account: @account)

    unused_tags = Tag.unused

    assert_includes unused_tags, unused_tag
    assert_not_includes unused_tags, web_tag
    assert_not_includes unused_tags, mobile_tag
  end

  test ".unused returns empty relation if all tags are used" do
    web_tag = Tag.create!(title: "web", account: @account)

    card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end
    card.taggings.create!(tag: web_tag, account: @account)

    Tag.unused.destroy_all
    assert_empty Tag.unused
  end
end
