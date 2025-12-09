require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    create(:user, :system, account: @account)

    @david_identity = create(:identity, :david)
    @kevin_identity = create(:identity, :kevin)
    @jz_identity = create(:identity, :jz)

    @david = create(:user, :david, account: @account, identity: @david_identity)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)
    @jz = create(:user, :jz, account: @account, identity: @jz_identity)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)

    @card = with_current_user(@david) do
      create(:card, :layout, board: @board, creator: @david, column: @column, account: @account)
    end

    travel_to Time.utc(2025, 1, 22, 17, 30, 0)

    @event = create(:event,
      account: @account,
      board: @board,
      creator: @david,
      eventable: @card,
      action: "card_assigned",
      particulars: { assignee_ids: [ @jz.id ] },
      created_at: Time.current.beginning_of_day + 8.hours
    )

    sign_in_as @kevin
  end

  test "index" do
    get events_path

    assert_select "div.events__time-block[style='grid-area: 17/2']" do
      assert_select "strong", text: /assigned JZ to Layout is broken/
    end
  end

  test "index with a specific timezone" do
    cookies[:timezone] = "America/New_York"

    get events_path

    assert_select "div.events__time-block[style='grid-area: 22/2']" do
      assert_select "strong", text: /assigned JZ to Layout is broken/
    end
  end

  test "only displays events from filtered boards" do
    get events_path(board_ids: [ @board.id ])
    assert_response :success

    events_shown = css_select(".event").count
    assert events_shown > 0, "Should show some events"

    css_select(".event").each do |event|
      assert_includes event.text, @board.name
    end
  end
end
