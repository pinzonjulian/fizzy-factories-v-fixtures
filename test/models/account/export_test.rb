require "test_helper"

class Account::ExportTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)
    with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account)
    end
  end

  test "build_later enqueues ExportAccountDataJob" do
    export = Account::Export.create!(account: @account, user: @david)

    assert_enqueued_with(job: ExportAccountDataJob, args: [ export ]) do
      export.build_later
    end
  end

  test "build generates zip with card JSON files" do
    export = Account::Export.create!(account: @account, user: @david)

    export.build

    assert export.completed?
    assert export.file.attached?
    assert_equal "application/zip", export.file.content_type
  end

  test "build sets status to processing then completed" do
    export = Account::Export.create!(account: @account, user: @david)

    export.build

    assert export.completed?
    assert_not_nil export.completed_at
  end

  test "build sends email when completed" do
    export = Account::Export.create!(account: @account, user: @david)

    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      export.build
    end
  end

  test "build sets status to failed on error" do
    export = Account::Export.create!(account: @account, user: @david)
    export.stubs(:generate_zip).raises(StandardError.new("Test error"))

    assert_raises(StandardError) do
      export.build
    end

    assert export.failed?
  end

  test "cleanup deletes exports completed more than 24 hours ago" do
    old_export = Account::Export.create!(account: @account, user: @david, status: :completed, completed_at: 25.hours.ago)
    recent_export = Account::Export.create!(account: @account, user: @david, status: :completed, completed_at: 23.hours.ago)
    pending_export = Account::Export.create!(account: @account, user: @david, status: :pending)

    Account::Export.cleanup

    assert_not Account::Export.exists?(old_export.id)
    assert Account::Export.exists?(recent_export.id)
    assert Account::Export.exists?(pending_export.id)
  end

  test "build includes only accessible cards for user" do
    export = Account::Export.create!(account: @account, user: @david)

    export.build

    assert export.completed?
    assert export.file.attached?

    Tempfile.create([ "test", ".zip" ]) do |temp|
      temp.binmode
      export.file.download { |chunk| temp.write(chunk) }
      temp.rewind

      Zip::File.open(temp.path) do |zip|
        json_files = zip.glob("*.json")
        assert json_files.any?, "Zip should contain at least one JSON file"

        json_content = JSON.parse(zip.read(json_files.first.name))
        assert json_content.key?("number")
        assert json_content.key?("title")
        assert json_content.key?("board")
        assert json_content.key?("creator")
        assert json_content["creator"].key?("id")
        assert json_content["creator"].key?("name")
        assert json_content["creator"].key?("email")
        assert json_content.key?("description")
        assert json_content.key?("comments")
      end
    end
  end
end
