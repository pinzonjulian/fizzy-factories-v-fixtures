require "test_helper"

class CardTest < ActiveSupport::TestCase
  setup do
    @account = Current.account

    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    @kevin_identity = create(:identity, :kevin)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)

    @jz_identity = create(:identity, :jz)
    @jz = create(:user, :jz, account: @account, identity: @jz_identity)

    create(:user, :system, account: @account)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @private_board = create(:board, :private, account: @account, creator: @kevin)

    @triage_column = create(:column, :writebook_triage, board: @board, account: @account)
    @in_progress_column = create(:column, :writebook_in_progress, board: @board, account: @account)

    @web_tag = create(:tag, :web, account: @account)
    @mobile_tag = create(:tag, :mobile, account: @account)

    @logo_card = with_current_user(@david) do
      card = @board.cards.create!(
        creator: @david,
        column: @triage_column,
        title: "The logo isn't big enough",
        due_on: 3.days.from_now,
        status: :published
      )
      card.toggle_assignment(@kevin)
      card.toggle_assignment(@jz)
      card.toggle_tag_with(@web_tag.title)
      card
    end

    @layout_card = with_current_user(@david) do
      card = @board.cards.create!(
        creator: @david,
        column: @triage_column,
        title: "Layout is broken",
        status: :published
      )
      card.toggle_assignment(@jz)
      card.toggle_tag_with(@web_tag.title)
      card.toggle_tag_with(@mobile_tag.title)
      card
    end

    @text_card = with_current_user(@kevin) do
      card = @board.cards.create!(
        creator: @kevin,
        column: @in_progress_column,
        title: "The text is too small",
        status: :published
      )
      card.toggle_tag_with(@mobile_tag.title)
      card
    end

    @shipping_card = with_current_user(@kevin) do
      card = @board.cards.create!(
        creator: @kevin,
        column: @triage_column,
        title: "We need to ship the app",
        status: :published
      )
      card.close(user: @kevin)
      card
    end

    @buy_domain_card = with_current_user(@david) do
      @board.cards.create!(
        creator: @david,
        title: "Buy domain",
        status: :published
      )
    end
  end

  test "create assigns a number to the card" do
    card = nil

    assert_difference -> { @account.reload.cards_count }, +1 do
      card = with_current_user(@david) do
        Card.create!(title: "Test", board: @board, creator: @david)
      end
    end

    assert_equal @account.reload.cards_count, card.number
  end

  test "capturing messages" do
    assert_difference -> { @logo_card.comments.count }, +1 do
      with_current_user(@david) do
        @logo_card.comments.create!(body: "Agreed.")
      end
    end

    assert_equal "Agreed.", @logo_card.comments.last.body.to_plain_text.chomp
  end

  test "assignment states" do
    assert @logo_card.assigned_to?(@kevin)
    assert_not @logo_card.assigned_to?(@david)
  end

  test "assignment toggling" do
    assert @logo_card.assigned_to?(@kevin)

    assert_difference({ -> { @logo_card.assignees.count } => -1, -> { Event.count } => +1 }) do
      with_current_user(@david) do
        @logo_card.toggle_assignment @kevin
      end
    end
    assert_not @logo_card.reload.assigned_to?(@kevin)
    unassign_event = Event.last
    assert_equal "card_unassigned", unassign_event.action
    assert_equal [ @kevin ], unassign_event.assignees

    assert_difference %w[ @logo_card.assignees.count Event.count ], +1 do
      with_current_user(@david) do
        @logo_card.toggle_assignment @kevin
      end
    end
    assert @logo_card.assigned_to?(@kevin)
    assign_event = Event.last
    assert_equal "card_assigned", assign_event.action
    assert_equal [ @kevin ], assign_event.assignees
  end

  test "tagged states" do
    assert @logo_card.tagged_with?(@web_tag)
    assert_not @logo_card.tagged_with?(@mobile_tag)
  end

  test "tag toggling" do
    assert @logo_card.tagged_with?(@web_tag)

    assert_difference "@logo_card.taggings.count", -1 do
      with_current_user(@david) do
        @logo_card.toggle_tag_with @web_tag.title
      end
    end
    assert_not @logo_card.tagged_with?(@web_tag)

    assert_difference "@logo_card.taggings.count", +1 do
      with_current_user(@david) do
        @logo_card.toggle_tag_with @web_tag.title
      end
    end
    assert @logo_card.tagged_with?(@web_tag)

    assert_difference %w[ @logo_card.taggings.count Tag.count ], +1 do
      with_current_user(@david) do
        @logo_card.toggle_tag_with "prioritized"
      end
    end
    assert_equal "prioritized", @logo_card.taggings.last.tag.title
  end

  test "closed" do
    assert_equal [ @shipping_card ], Card.closed
  end

  test "open" do
    assert_equal [ @logo_card, @layout_card, @text_card, @buy_domain_card ].to_set, @account.cards.open.to_set
  end

  test "card_unassigned" do
    assert_equal [ @shipping_card, @text_card, @buy_domain_card ].to_set, @account.cards.unassigned.to_set
  end

  test "assigned to" do
    assert_equal [ @logo_card, @layout_card ].to_set, Card.assigned_to(@jz).to_set
  end

  test "assigned by" do
    assert_equal [ @layout_card, @logo_card ].to_set, Card.assigned_by(@david).to_set
  end

  test "in board" do
    new_board = with_current_user(@david) do
      Board.create! name: "New Board", creator: @david
    end
    assert_equal [ @logo_card, @shipping_card, @layout_card, @text_card, @buy_domain_card ].to_set, Card.where(board: @board).to_set
    assert_empty Card.where(board: new_board)
  end

  test "tagged with" do
    assert_equal [ @layout_card, @text_card ], Card.tagged_with(@mobile_tag)
  end

  test "for published cards, it should set the default title 'Untitiled' when not provided" do
    card = with_current_user(@david) do
      @board.cards.create!
    end
    assert_nil card.title

    card.publish
    assert_equal "Untitled", card.reload.title
  end

  test "send back to triage when moved to a new board" do
    with_current_user(@david) do
      @logo_card.update! column: @in_progress_column
    end

    assert_changes -> { @logo_card.reload.triaged? }, from: true, to: false do
      with_current_user(@david) do
        @logo_card.update! board: @private_board
      end
    end
  end

  test "grants access to assignees when moved to a new board" do
    card = @logo_card
    assignee = @david
    with_current_user(@david) do
      card.toggle_assignment(assignee)
    end

    board = @private_board
    assert_not_includes board.users, assignee

    with_current_user(@david) do
      card.update!(board: board)
    end
    assert_includes board.users.reload, assignee
  end

  test "move cards to a different board" do
    card = @logo_card
    old_board = @board
    new_board = @private_board

    assert_equal old_board, card.board

    assert card.events.where(board: old_board).exists?

    with_current_user(@david) do
      card.move_to(new_board)
    end

    assert_equal new_board, card.reload.board

    events_in_old_board = card.events.where(board: old_board)
    events_in_new_board = card.events.where(board: new_board)

    assert_empty events_in_old_board
    assert events_in_new_board.exists?

    board_changed_event = events_in_new_board.find { |event| event.action == "card_board_changed" }
    assert board_changed_event
  end

  test "a card is filled if it has either the title or the description set" do
    assert Card.new(title: "Some title").filled?
    assert Card.new(description: "Some description").filled?

    assert_not Card.new.filled?
  end
end
