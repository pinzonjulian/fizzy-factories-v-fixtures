require "test_helper"

class ReactionTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions.david
  end

  test "creating a reaction touches the card activity" do
    assert_changes -> { cards.logo.reload.last_active_at } do
      comments.logo_agreement_jz.reactions.create!(content: "Nice!")
    end
  end
end
