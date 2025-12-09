require "test_helper"

class FilterTest < ActiveSupport::TestCase
  setup do
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @account = Current.account

    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)

    @kevin_identity = create(:identity, :kevin)
    @kevin = create(:user, :kevin, account: @account, identity: @kevin_identity)

    @jz_identity = create(:identity, :jz)
    @jz = create(:user, :jz, account: @account, identity: @jz_identity)

    @writebook = create(:board, :writebook, account: @account, creator: @david)
    @private_board = create(:board, :private, account: @account, creator: @kevin)
    @column = create(:column, :writebook_triage, board: @writebook, account: @account)

    @logo = with_current_user(@david) do
      create(:card, :logo, board: @writebook, column: @column, account: @account, creator: @david)
    end

    @layout = with_current_user(@david) do
      create(:card, :layout, board: @writebook, column: @column, account: @account, creator: @david)
    end

    @shipping = with_current_user(@kevin) do
      create(:card, :shipping, board: @writebook, column: @column, account: @account, creator: @kevin)
    end

    @mobile = create(:tag, title: "mobile", account: @account)
    @web = create(:tag, title: "web", account: @account)

    create(:tagging, card: @layout, tag: @mobile, account: @account)

    create(:closure, card: @shipping, user: @kevin, account: @account)

    @jz_assignments_filter = @jz.filters.create!(
      sorted_by: "newest",
      tag_ids: [@mobile.id],
      assignee_ids: [@jz.id]
    )

    @initech = create(:account, :initech)
    create(:user, :system_initech, account: @initech)
    @mike_identity = create(:identity, :mike)
    @mike = create(:user, :mike, account: @initech, identity: @mike_identity)
    @miltons_wish_list = create(:board, :miltons_wish_list, account: @initech, creator: @mike)
  end

  test "cards" do
    @new_board = Board.create! name: "Inaccessible Board", creator: @david
    @new_card = @new_board.cards.create!(status: "published")

    @layout.comments.create!(body: "I hate haggis")
    @logo.comments.create!(body: "I love haggis")

    assert_not_includes @kevin.filters.new.cards, @new_card

    filter = @david.filters.new creator_ids: [ @david.id ], tag_ids: [ @mobile.id ]
    assert_equal [ @layout ], filter.cards

    filter = @david.filters.new assignment_status: "unassigned", board_ids: [ @new_board.id ]
    assert_equal [ @new_card ], filter.cards

    filter = @david.filters.new indexed_by: "closed"
    assert_equal [ @shipping ], filter.cards

    @shipping.postpone
    filter = @david.filters.new indexed_by: "not_now"
    assert_includes filter.cards, @shipping

    filter = @david.filters.new card_ids: [ [@logo, @layout].collect(&:id) ]
    assert_equal [ @logo, @layout ], filter.cards
  end

  test "can't see cards in boards that aren't accessible" do
    @writebook.update! all_access: false
    @writebook.accesses.revoke_from @david

    assert_empty @david.filters.new(board_ids: [ @writebook.id ]).cards
  end

  test "can't see boards that aren't accessible" do
    @writebook.update! all_access: false
    @writebook.accesses.revoke_from @david

    assert_empty @david.filters.new(board_ids: [ @writebook.id ]).boards
  end

  test "remembering equivalent filters" do
    assert_difference "Filter.count", +1 do
      filter = @david.filters.remember(sorted_by: "latest", assignment_status: "unassigned", tag_ids: [ @mobile.id ])

      assert_changes "filter.reload.updated_at" do
        assert_equal filter, @david.filters.remember(tag_ids: [ @mobile.id ], assignment_status: "unassigned")
      end
    end
  end

  test "remembering equivalent filters for different users" do
    assert_difference "Filter.count", +2 do
      @david.filters.remember(assignment_status: "unassigned", tag_ids: [ @mobile.id ])
      @kevin.filters.remember(assignment_status: "unassigned", tag_ids: [ @mobile.id ])
    end
  end

  test "turning into params" do
    filter = @david.filters.new sorted_by: "latest", tag_ids: "", assignee_ids: [ @jz.id ], board_ids: [ @writebook.id ]
    expected = { assignee_ids: [ @jz.id ], board_ids: [ @writebook.id ] }
    assert_equal expected, filter.as_params
  end

  test "cacheability" do
    assert_not @jz_assignments_filter.cacheable?
    assert @david.filters.create!(board_ids: [ @writebook.id ]).cacheable?
  end

  test "terms" do
    assert_equal [], @david.filters.new.terms
    assert_equal [ "haggis" ], @david.filters.new(terms: [ "haggis" ]).terms
  end

  test "resource removal" do
    filter = @david.filters.create! tag_ids: [ @mobile.id ], board_ids: [ @writebook.id ]

    assert_includes filter.as_params[:tag_ids], @mobile.id
    assert_includes filter.tags, @mobile
    assert_includes filter.as_params[:board_ids], @writebook.id
    assert_includes filter.boards, @writebook

    assert_changes "filter.reload.updated_at" do
      @mobile.destroy!
    end
    assert_nil Filter.find(filter.id).as_params[:tag_ids]

    assert_changes "Filter.exists?(filter.id)" do
      @writebook.destroy!
    end
  end

  test "duplicate filters are removed after a resource is destroyed" do
    @david.filters.create! tag_ids: [ @mobile.id ], board_ids: [ @writebook.id ]
    @david.filters.create! tag_ids: [ @mobile.id, @web.id ], board_ids: [ @writebook.id ]

    assert_difference "Filter.count", -1 do
      @web.destroy!
    end
  end

  test "summary" do
    assert_equal "Newest, #mobile, and assigned to JZ", @jz_assignments_filter.summary

    @jz_assignments_filter.update!(assignees: [], tags: [], boards: [ @writebook ])
    assert_equal "Newest", @jz_assignments_filter.summary

    @jz_assignments_filter.update!(indexed_by: "stalled", sorted_by: "latest")
    assert_equal "Stalled", @jz_assignments_filter.summary
  end

  test "get a clone with some changed params" do
    seed_filter = @david.filters.new indexed_by: "all", terms: [ "haggis" ]
    filter = seed_filter.with(indexed_by: "closed")

    assert filter.indexed_by.closed?
    assert_equal [ "haggis" ], filter.terms
  end

  test "creation window" do
    filter = @david.filters.new creation: "this week"

    @logo.update_columns created_at: 2.weeks.ago
    assert_not_includes filter.cards, @logo

    @logo.update_columns created_at: Time.current
    assert_includes filter.cards, @logo
  end

  test "closure window" do
    filter = @david.filters.new closure: "this week"

    @shipping.closure.update_columns created_at: 2.weeks.ago
    assert_not_includes filter.cards, @shipping

    @shipping.closure.update_columns created_at: Time.current
    assert_includes filter.cards, @shipping
  end

  test "completed by" do
    @shipping.closure.update_columns user_id: @david.id

    filter = @david.filters.new closer_ids: [ @david.id ]
    assert_includes filter.cards, @shipping

    filter = @david.filters.new closer_ids: [ @jz.id ]
    assert_not_includes filter.cards, @shipping

    @shipping.closure.update_columns user_id: @jz.id

    filter = @david.filters.new closer_ids: [ @jz.id ]
    assert_includes filter.cards, @shipping
  end

  test "check if a filter is used" do
    assert @david.filters.new(creator_ids: [ @david.id ]).used?
    assert_not @david.filters.new.used?

    assert @david.filters.new(board_ids: [ @writebook.id ]).used?
    assert_not @david.filters.new(board_ids: [ @writebook.id ]).used?(ignore_boards: true)
  end

  test "board titles are scoped to creator's account" do
    @miltons_wish_list.accesses.grant_to(@mike)
    assert_equal 1, @mike.boards.count

    filter = @mike.filters.new(creator: @mike)
    assert_equal [ "Milton's Wish List" ], filter.board_titles

    assert Board.where.not(account: @initech).exists?
    assert_not_includes filter.board_titles, "Writebook"
    assert_not_includes filter.board_titles, "Private board"
  end
end
