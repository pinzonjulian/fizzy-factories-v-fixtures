require "test_helper"

class ColumnLimitsTest < ActiveSupport::TestCase
  # Database errors for exceeding column limits:
  # - MySQL: ActiveRecord::ValueTooLong
  # - SQLite: ActiveRecord::CheckViolation
  COLUMN_LIMIT_ERRORS = [ ActiveRecord::ValueTooLong, ActiveRecord::CheckViolation ]

  setup do
    david_identity = create(:identity, :david)
    Current.session = create(:session, identity: david_identity)
    @account = Current.account

    create(:user, :system, account: @account)
    @david = create(:user, :david, account: @account, identity: david_identity)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)

    @card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end
  end

  test "account name rejects strings over 255 characters" do
    account = Account.new(name: "a" * 256)
    assert_raises(*COLUMN_LIMIT_ERRORS) { account.save! }
  end

  test "account name accepts strings up to 255 characters" do
    account = Account.new(name: "a" * 255)
    assert account.save
  end

  test "account name accepts 255 emoji characters" do
    account = Account.new(name: "🎉" * 255)
    assert account.save
  end

  test "account name rejects 256 emoji characters" do
    account = Account.new(name: "🎉" * 256)
    assert_raises(*COLUMN_LIMIT_ERRORS) { account.save! }
  end

  # Test text column limits (65535 bytes for TEXT)
  test "step content rejects text over 65535 bytes" do
    step = Step.new(content: "a" * 65536, card: @card)
    assert_raises(*COLUMN_LIMIT_ERRORS) { step.save! }
  end

  test "step content accepts text up to 65535 bytes" do
    step = Step.new(content: "a" * 65535, card: @card)
    assert step.save
  end

  test "step content counts bytes not characters for text columns" do
    # 20000 emoji = 20000 chars but 80000 bytes (over 65535 limit)
    step = Step.new(content: "🎉" * 20000, card: @card)
    assert_raises(*COLUMN_LIMIT_ERRORS) { step.save! }
  end

  test "ActionText::RichText name rejects strings over 255 characters" do
    rich_text = ActionText::RichText.new(name: "a" * 256, record: @card)
    assert_raises(*COLUMN_LIMIT_ERRORS) { rich_text.save! }
  end

  test "ActiveStorage::Blob filename rejects strings over 255 characters" do
    blob = ActiveStorage::Blob.new(filename: "a" * 256, key: "test-key", byte_size: 0, checksum: "test", service_name: "local")
    assert_raises(*COLUMN_LIMIT_ERRORS) { blob.save! }
  end
end
