require "test_helper"

class User::RoleTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    create(:user, :system, account: @account)
    @jason = create(:user, :jason, account: @account)
    @kevin = create(:user, :kevin, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @jz = create(:user, :jz, account: @account)
  end

  test "can administer others?" do
    assert @kevin.can_administer?(@jz)

    assert_not @kevin.can_administer?(@kevin)
    assert_not @jz.can_administer?(@kevin)
  end

  test "owner can administer admins and members" do
    assert @jason.can_administer?(@kevin)
    assert @jason.can_administer?(@david)
    assert @jason.can_administer?(@jz)
  end

  test "owner cannot administer themselves" do
    assert_not @jason.can_administer?(@jason)
  end

  test "admin cannot administer the owner" do
    assert_not @kevin.can_administer?(@jason)
  end

  test "owner is included in active scope" do
    system_user = @account.users.find_by(role: :system)
    active_users = User.active
    assert_includes active_users, @jason
    assert_includes active_users, @kevin
    assert_includes active_users, @david
    assert_not_includes active_users, system_user
  end

  test "owner is also considered an admin" do
    assert @jason.owner?
    assert @jason.admin?

    assert @kevin.admin?
    assert_not @kevin.owner?
  end

  test "owner scope returns only active owners" do
    owners = @account.users.owner
    assert_includes owners, @jason
    assert_not_includes owners, @kevin
    assert_not_includes owners, @david

    @jason.update!(active: false)
    assert_not_includes @account.users.owner, @jason
  end

  test "admin scope returns active owners and admins" do
    admins = @account.users.admin
    assert_includes admins, @jason
    assert_includes admins, @kevin
    assert_not_includes admins, @david

    @kevin.update!(active: false)
    assert_not_includes @account.users.admin, @kevin
  end

  test "can administer board?" do
    writebook_board = create(:board, :writebook, account: @account, creator: @david)
    private_board = create(:board, :private, account: @account, creator: @kevin)

    # Admin can administer any board
    assert @kevin.can_administer_board?(writebook_board)
    assert @kevin.can_administer_board?(private_board)

    # Creator can administer their own board
    assert @david.can_administer_board?(writebook_board)

    # Regular user cannot administer boards they didn't create
    assert_not @jz.can_administer_board?(writebook_board)
    assert_not @jz.can_administer_board?(private_board)

    # Creator cannot administer other people's boards
    assert_not @david.can_administer_board?(private_board)
  end

  test "can administer card?" do
    writebook_board = create(:board, :writebook, account: @account, creator: @david)
    column = create(:column, :writebook_triage, account: @account, board: writebook_board)

    logo_card = nil
    text_card = nil
    with_current_user(@david) do
      logo_card = create(:card, :logo, account: @account, board: writebook_board, column: column, creator: @david)
      text_card = create(:card, :text, account: @account, board: writebook_board, column: column, creator: @kevin)
    end

    # Admin can administer any card
    assert @kevin.can_administer_card?(logo_card)
    assert @kevin.can_administer_card?(text_card)

    # Creator can administer their own card
    assert @david.can_administer_card?(logo_card)

    # Regular user cannot administer cards they didn't create
    assert_not @jz.can_administer_card?(logo_card)
    assert_not @jz.can_administer_card?(text_card)

    # Creator cannot administer other people's cards
    assert_not @david.can_administer_card?(text_card)
  end
end
