require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @account = Current.account

    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    @jz_identity = create(:identity, :jz)
    @jz = create(:user, :jz, account: @account, identity: @jz_identity)

    @kevin_identity = create(:identity, :kevin)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)

    create(:user, :system, account: @account)

    @board = create(:board, :writebook, account: @account, creator: @david)
  end

  test "create" do
    user = User.create!(
      account: @account,
      role: "member",
      name: "Victor Cooper"
    )

    assert_equal [ @board ], user.boards
    assert user.settings.present?
  end

  test "creation gives access to all_access boards" do
    user = User.create!(
      account: @account,
      role: "member",
      name: "Victor Cooper"
    )

    assert_equal [ @board ], user.boards
  end

  test "deactivate" do
    assert_changes -> { @jz.active? }, from: true, to: false do
      assert_changes -> { @jz.accesses.count }, from: 1, to: 0 do
        @jz.tap do |user|
          user.stubs(:close_remote_connections).once
          user.deactivate
        end
      end
    end
  end

  test "initials" do
    assert_equal "JF", User.new(name: "jason fried").initials
    assert_equal "DHH", User.new(name: "David Heinemeier Hansson").initials
    assert_equal "ÉLH", User.new(name: "Éva-Louise Hernández").initials
  end

  test "setup?" do
    @kevin.update!(name: @kevin.identity.email_address)
    assert_not @kevin.setup?

    @kevin.update!(name: "Kevin")
    assert @kevin.setup?
  end

  test "verified? returns true when verified_at is present" do
    @david.update_column(:verified_at, Time.current)

    assert @david.verified?
  end

  test "verified? returns false when verified_at is nil" do
    @david.update_column(:verified_at, nil)

    assert_not @david.verified?
  end

  test "verify sets verified_at when not already verified" do
    @david.update_column(:verified_at, nil)

    assert_nil @david.verified_at
    @david.verify
    assert_not_nil @david.reload.verified_at
  end

  test "verify does not update verified_at when already verified" do
    original_time = 1.day.ago
    @david.update_column(:verified_at, original_time)

    @david.verify
    assert_equal original_time.to_i, @david.reload.verified_at.to_i
  end
end
