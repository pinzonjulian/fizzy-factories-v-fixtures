require "test_helper"

class MentionsTest < ActiveSupport::TestCase
  setup do
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @account = Current.account

    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    @kevin_identity = create(:identity, :kevin)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)

    @jz_identity = create(:identity, :jz)
    @jz = create(:user, :jz, account: @account, identity: @jz_identity)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)
  end

  test "don't create mentions when creating or updating drafts" do
    assert_no_difference -> { Mention.count } do
      perform_enqueued_jobs only: Mention::CreateJob do
        card = with_current_user(@david) do
          @board.cards.create title: "Cleanup", description: "Did you finish up with the cleanup, #{mention_html_for(@david)}?"
        end
        card.update description: "Any thoughts here #{mention_html_for(@jz)}"
      end
    end
  end

  test "create mentions from plain text mentions when publishing cards" do
    perform_enqueued_jobs only: Mention::CreateJob do
      card = assert_no_difference -> { Mention.count } do
        with_current_user(@david) do
          @board.cards.create title: "Cleanup", description: "Did you finish up with the cleanup, #{mention_html_for(@david)}?"
        end
      end

      card = Card.find(card.id)

      assert_difference -> { Mention.count }, +1 do
        card.publish
      end
    end
  end

  test "create mentions from rich text mentions when publishing cards" do
    perform_enqueued_jobs only: Mention::CreateJob do
      card = assert_no_difference -> { Mention.count } do
        with_current_user(@david) do
          @board.cards.create title: "Cleanup", description: "Did you finish up with the cleanup, #{mention_html_for(@david)}?"
        end
      end

      card = Card.find(card.id)

      assert_difference -> { Mention.count }, +1 do
        card.published!
      end
    end
  end

  test "don't create repeated mentions when updating cards" do
    perform_enqueued_jobs only: Mention::CreateJob do
      card = with_current_user(@david) do
        @board.cards.create title: "Cleanup", description: "Did you finish up with the cleanup, #{mention_html_for(@david)}?"
      end

      assert_difference -> { Mention.count }, +1 do
        card.published!
      end

      assert_no_difference -> { Mention.count } do
        card.update description: "Any thoughts here #{mention_html_for(@david)}"
      end

      assert_difference -> { Mention.count }, +1 do
        card.update description: "Any thoughts here #{mention_html_for(@jz)}"
      end
    end
  end

  test "create mentions from plain text mentions when posting comments" do
    perform_enqueued_jobs only: Mention::CreateJob do
      card = with_current_user(@david) do
        @board.cards.create title: "Cleanup", description: "Some initial content", status: :published
      end

      assert_difference -> { Mention.count }, +1 do
        card.comments.create!(body: "Great work on this #{mention_html_for(@david)}!")
      end
    end
  end

  test "don't create mentions from comments when belonging to unpublished cards" do
    perform_enqueued_jobs only: Mention::CreateJob do
      card = with_current_user(@david) do
        @board.cards.create title: "Cleanup", description: "Some initial content"
      end

      assert_no_difference -> { Mention.count } do
        card.comments.create!(body: "Great work on this #{mention_html_for(@david)}!")
      end
    end
  end

  test "can't mention users that don't have access to the board" do
    @board.update! all_access: false
    @board.accesses.revoke_from(@david)

    assert_no_difference -> { Mention.count }, +1 do
      perform_enqueued_jobs only: Mention::CreateJob do
        with_current_user(@david) do
          @board.cards.create title: "Cleanup", description: "Did you finish up with the cleanup, #{mention_html_for(@david)}?"
        end
      end
    end
  end

  test "mentionees are added as watchers of the card" do
    perform_enqueued_jobs only: Mention::CreateJob do
      card = with_current_user(@david) do
        @board.cards.create title: "Cleanup", description: "Did you finish up with the cleanup #{mention_html_for(@kevin)}?"
      end
      card.published!
      assert card.watchers.include?(@kevin)
    end
  end

  private
    def mention_html_for(user)
      ActionText::Attachment.from_attachable(user).to_html
    end
end
