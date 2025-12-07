require "test_helper"

class User::MentionableTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    @jz_identity = create(:identity, :jz)
    Current.session = create(:session, identity: @david_identity)
    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @jz = create(:user, :jz, account: @account, identity: @jz_identity)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)

    @card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end
  end

  test "mentionable handles" do
    assert_equal [ "dhh", "david", "davidh" ], User.new(name: "David Heinemeier-Hansson").mentionable_handles
  end

  test "mentioned by" do
    @david.mentions.destroy_all

    assert_difference -> { @david.mentions.count }, +1 do
      @david.mentioned_by @jz, at: @card
    end

    # No dups
    assert_no_difference -> { @david.mentions.count }, +1 do
      @david.mentioned_by @jz, at: @card
    end
  end
end
