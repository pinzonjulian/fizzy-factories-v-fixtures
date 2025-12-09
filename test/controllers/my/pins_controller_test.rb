require "test_helper"

class My::PinsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @kevin = create(:user, :kevin, account: @account)
    board = create(:board, :writebook, account: @account, creator: @kevin)
    column = create(:column, :writebook_triage, board: board, account: @account)

    card = with_current_user(@kevin) do
      create(:card, :logo, board: board, column: column, account: @account, creator: @kevin)
    end
    create(:pin, card: card, user: @kevin, account: @account)

    sign_in_as @kevin
  end

  test "index" do
    get my_pins_path

    assert_response :success
    assert_select "div", text: /#{@kevin.pins.first.card.title}/
  end
end
