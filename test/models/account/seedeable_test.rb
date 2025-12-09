require "test_helper"

class Account::SedeableTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @kevin_identity = create(:identity, :kevin)
    Current.session = create(:session, identity: @kevin_identity)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)
  end

  test "setup_customer_template adds boards, cards, and comments" do
    assert_changes -> { Board.count } do
      assert_changes -> { Card.count } do
        @account.setup_customer_template
      end
    end
  end
end
