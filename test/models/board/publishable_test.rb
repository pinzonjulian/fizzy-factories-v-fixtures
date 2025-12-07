require "test_helper"

class Board::PublishableTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @writebook = create(:board, :writebook, account: @account, creator: @david)
    @private_board = create(:board, :private, account: @account, creator: @david)
  end

  test "published scope" do
    @writebook.publish
    assert_includes Board.published, @writebook
    assert_not_includes Board.published, @private_board
  end

  test "published?" do
    assert_not @writebook.published?
    @writebook.publish
    assert @writebook.published?
  end

  test "publish and unpublish" do
    assert_not @writebook.published?

    assert_difference -> { Board::Publication.count }, +1 do
      @writebook.publish
    end

    assert @writebook.published?

    assert_difference -> { Board::Publication.count }, -1 do
      @writebook.unpublish
    end

    assert_not @writebook.reload.published?
  end

  test "find board by publication key" do
    @writebook.publish
    assert_equal @writebook, Board.find_by_published_key(@writebook.publication.key)

    assert_raise ActiveRecord::RecordNotFound do
      Board.find_by_published_key("invalid")
    end
  end

  test "publish doesn't create duplicate publications" do
    @writebook.publish
    original_publication = @writebook.publication

    assert_no_difference -> { Board::Publication.count } do
      @writebook.publish
    end

    assert_equal original_publication, @writebook.reload.publication
  end
end
