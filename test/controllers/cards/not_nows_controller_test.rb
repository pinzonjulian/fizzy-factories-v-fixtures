require "test_helper"

class Cards::NotNowsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "create" do
    card = cards.logo

    assert_changes -> { card.reload.postponed? }, from: false, to: true do
      post card_not_now_path(card)
      assert_card_container_rerendered(card)
    end
  end
end
