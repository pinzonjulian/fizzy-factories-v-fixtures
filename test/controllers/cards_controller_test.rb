require "test_helper"

class CardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @identity_david = create(:identity, :david)
    @identity_kevin = create(:identity, :kevin)
    @identity_jz = create(:identity, :jz)
    @david = create(:user, :david, account: @account, identity: @identity_david)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @kevin = create(:user, :kevin, account: @account, identity: @identity_kevin)
    @jz = create(:user, :jz, account: @account, identity: @identity_jz)
    @column = create(:column, :writebook_triage, board: @board, account: @account)
    @mobile_tag = create(:tag, :mobile, account: @account)

    @logo_card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end

    sign_in_as @kevin
  end

  test "index" do
    get cards_path
    assert_response :success
  end

  test "filtered index" do
    filter = create(:filter, :jz_assignments, account: @account, creator: @david, tag: @mobile_tag, assignee: @jz)
    get cards_path(filter.as_params.merge(term: "haggis"))
    assert_response :success
  end

  test "create a new draft" do
    assert_difference -> { Card.count }, 1 do
      post board_cards_path(@board)
    end

    card = Card.last
    assert card.drafted?
    assert_redirected_to card
  end

  test "create resumes existing draft if it exists" do
    draft = with_current_user(@kevin) do
      @board.cards.create!(creator: @kevin, status: :drafted)
    end

    assert_no_difference -> { Card.count } do
      post board_cards_path(@board)
    end

    assert_redirected_to draft
  end

  test "show" do
    get card_path(@logo_card)
    assert_response :success
  end

  test "edit" do
    get edit_card_path(@logo_card)
    assert_response :success
  end

  test "update" do
    puts "Card number: #{@logo_card.number}"
    puts "Card id: #{@logo_card.id}"
    puts "Kevin accesses: #{@kevin.accesses.pluck(:board_id)}"
    puts "Kevin boards: #{@kevin.boards.pluck(:id)}"
    puts "Board id: #{@board.id}"
    puts "Kevin accessible_cards count: #{@kevin.accessible_cards.count}"
    puts "Kevin accessible_cards by number: #{@kevin.accessible_cards.find_by(number: @logo_card.number)}"
    puts "Kevin id: #{@kevin.id}"
    puts "Kevin identity id: #{@kevin.identity.id}"
    puts "Kevin identity users: #{@kevin.identity.users.pluck(:id)}"
    puts "Account: #{@account.id}"
    puts "Kevin account: #{@kevin.account_id}"
    puts "Card path: #{card_path(@logo_card)}"
    puts "Card to_param: #{@logo_card.to_param}"

    get card_path(@logo_card)
    puts "GET response: #{response.status}"

    patch card_path(@logo_card), as: :turbo_stream, params: {
      card: {
        title: "Logo needs to change",
        image: fixture_file_upload("moon.jpg", "image/jpeg"),
        description: "Something more in-depth",
        tag_ids: [ @mobile_tag.id ] } }
    assert_response :success

    card = @logo_card.reload
    assert_equal "Logo needs to change", card.title
    assert_equal "moon.jpg", card.image.filename.to_s
    assert_equal [ @mobile_tag ], card.tags

    assert_equal "Something more in-depth", card.description.to_plain_text.strip
  end

  test "users can only see cards in boards they have access to" do
    get card_path(@logo_card)
    assert_response :success

    @board.update! all_access: false
    @board.accesses.revoke_from @kevin
    get card_path(@logo_card)
    assert_response :not_found
  end

  test "admins can see delete button on any card" do
    get card_path(@logo_card)
    assert_response :success
    assert_match "Delete this card", response.body
  end

  test "card creators can see delete button on their own cards" do
    logout_and_sign_in_as @david

    get card_path(@logo_card)
    assert_response :success
    assert_match "Delete this card", response.body
  end

  test "non-admins cannot see delete button on cards they did not create" do
    logout_and_sign_in_as @jz

    get card_path(@logo_card)
    assert_response :success
    assert_no_match "Delete this card", response.body
  end

  test "non-admins cannot delete cards they did not create" do
    logout_and_sign_in_as @jz

    assert_no_difference -> { Card.count } do
      delete card_path(@logo_card)
    end

    assert_response :forbidden
  end

  test "card creators can delete their own cards" do
    logout_and_sign_in_as @david

    assert_difference -> { Card.count }, -1 do
      delete card_path(@logo_card)
    end

    assert_redirected_to @board
  end

  test "admins can delete any card" do
    assert_difference -> { Card.count }, -1 do
      delete card_path(@logo_card)
    end

    assert_redirected_to @board
  end

  test "show card with comment containing malformed remote image attachment" do
    with_current_user(@kevin) do
      @logo_card.comments.create!(
        creator: @kevin,
        body: '<action-text-attachment url="image.png" content-type="image/*" presentation="gallery"></action-text-attachment>'
      )
    end

    get card_path(@logo_card)
    assert_response :success
  end
end
