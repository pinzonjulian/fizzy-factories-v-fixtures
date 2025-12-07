require "test_helper"

class Cards::PinsControllerTest < ActionDispatch::IntegrationTest
  test "create" do
    account = Current.account
    kevin = create(:user, :kevin, account: account)
    board = create(:board, :writebook, account: account, creator: kevin)
    column = create(:column, :writebook_triage, board: board, account: account)

    card = with_current_user(kevin) do
      create(:card, :layout, board: board, column: column, account: account, creator: kevin)
    end

    sign_in_as kevin

    assert_changes -> { card.pinned_by?(kevin) }, from: false, to: true do
      perform_enqueued_jobs do
        assert_turbo_stream_broadcasts([ kevin, :pins_tray ], count: 1) do
          post card_pin_path(card), as: :turbo_stream
        end
      end
    end

    assert_response :success
  end

  test "destroy" do
    account = Current.account
    kevin = create(:user, :kevin, account: account)
    board = create(:board, :writebook, account: account, creator: kevin)
    column = create(:column, :writebook_triage, board: board, account: account)

    card = with_current_user(kevin) do
      create(:card, :shipping, board: board, column: column, account: account, creator: kevin)
    end
    create(:pin, card: card, user: kevin, account: account)

    sign_in_as kevin

    assert_changes -> { card.pinned_by?(kevin) }, from: true, to: false do
      perform_enqueued_jobs do
        assert_turbo_stream_broadcasts([ kevin, :pins_tray ], count: 1) do
          delete card_pin_path(card), as: :turbo_stream
        end
      end
    end

    assert_response :success
  end
end
