require "test_helper"

class Card::MessagesTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @kevin_identity = create(:identity, :kevin)
    Current.session = create(:session, identity: @kevin_identity)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)
    create(:user, :system, account: @account)
    @board = create(:board, :writebook, account: @account, creator: @kevin)
  end

  test "creating a card does not create a message by default" do
    card = @board.cards.create! creator: @kevin, title: "New"

    assert_empty card.comments
  end
end
