require "test_helper"

class Card::ExportableTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)
  end

  test "export_json returns card data as JSON" do
    card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end

    5.times do
      create(:comment, card: card, creator: @david, account: @account)
    end

    json = JSON.parse(card.export_json)

    assert_equal 1, json["number"]
    assert_equal "The logo isn't big enough", json["title"]
    assert_equal "Writebook", json["board"]
    assert_equal "Triage", json["status"]
    assert_equal @david.id, json["creator"]["id"]
    assert_equal "David", json["creator"]["name"]
    assert_equal @david_identity.email_address, json["creator"]["email"]
    assert_equal "", json["description"]
    assert_equal 5, json["comments"].count
    assert_equal card.created_at.iso8601, json["created_at"]
    assert_equal card.updated_at.iso8601, json["updated_at"]
  end

  test "export_attachments returns attachment paths and blobs" do
    card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end

    blob = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture("moon.jpg").open,
      filename: "moon.jpg",
      content_type: "image/jpeg"
    )
    attachment_html = ActionText::Attachment.from_attachable(blob).to_html
    card.update!(description: "<p>Here is an image:</p>#{attachment_html}")

    attachments = card.export_attachments

    assert_equal 1, attachments.count
    assert_equal file_fixture("moon.jpg").binread, attachments.first[:blob].download
    assert attachments.first[:path].start_with?("#{card.number}/")
  end
end
