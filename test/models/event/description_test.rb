require "test_helper"

class Event::DescriptionTest < ActiveSupport::TestCase
  setup do
    david_identity = create(:identity, :david)
    Current.session = create(:session, identity: david_identity)
    @account = Current.account

    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: david_identity)

    jz_identity = create(:identity, :jz)
    @jz = create(:user, :jz, account: @account, identity: jz_identity)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)

    @logo_card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end

    @layout_card = with_current_user(@david) do
      create(:card, :layout, board: @board, column: @column, account: @account, creator: @david)
    end

    @logo_published_event = Event.create!(
      creator: @david,
      board: @board,
      eventable: @logo_card,
      action: "card_published",
      account: @account,
      created_at: 1.week.ago
    )

    @layout_comment = Comment.create!(
      card: @layout_card,
      creator: @david,
      account: @account
    )

    @layout_commented_event = Event.create!(
      creator: @david,
      board: @board,
      eventable: @layout_comment,
      action: "comment_created",
      account: @account,
      created_at: 1.week.ago
    )
  end

  test "generates html description for card published event" do
    description = @logo_published_event.description_for(@david)

    assert_includes description.to_html, "added"
    assert_includes description.to_html, "logo"
  end

  test "generates plain text description for card published event" do
    description = @logo_published_event.description_for(@david)

    assert_includes description.to_plain_text, "David added"
    assert_includes description.to_plain_text, "logo"
  end

  test "generates description for comment event" do
    description = @layout_commented_event.description_for(@jz)

    assert_includes description.to_plain_text, "David commented on"
  end

  test "uses always the name even when the event creator is the current user" do
    description = @logo_published_event.description_for(@david)

    assert_includes description.to_plain_text, "David added"
  end

  test "uses creator name when event creator is not the current user" do
    description = @logo_published_event.description_for(@jz)

    assert_includes description.to_plain_text, "David added"
  end
end
