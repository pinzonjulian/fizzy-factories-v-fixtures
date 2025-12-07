require "test_helper"

class Cards::ReadingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @system_user = create(:user, :system, account: @account)
    @identity_david = create(:identity, :david)
    @identity_kevin = create(:identity, :kevin)
    @david = create(:user, :david, account: @account, identity: @identity_david)
    @kevin = create(:user, :kevin, account: @account, identity: @identity_kevin)

    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, account: @account, board: @board)

    @card = with_current_user(@david) do
      create(:card, :logo, account: @account, board: @board, column: @column, creator: @david)
    end

    @access = @kevin.accesses.find_by(board: @board)
    @access.update!(accessed_at: nil)

    @logo_published_event = create(:event, :logo_published, account: @account, board: @board, eventable: @card, creator: @david)
    @logo_assignment_event = create(:event, :logo_assignment_km, account: @account, board: @board, eventable: @card, creator: @david,
                                    particulars: { assignee_ids: [@kevin.id] }.to_json)

    @logo_published_notification = create(:notification, :logo_published_kevin, account: @account, user: @kevin, source: @logo_published_event, creator: @david)
    @logo_assignment_notification = create(:notification, :logo_assignment_kevin, account: @account, user: @kevin, source: @logo_assignment_event, creator: @david)

    sign_in_as @kevin
  end

  test "create" do
    freeze_time

    assert_changes -> { @logo_published_notification.reload.read? }, from: false, to: true do
      assert_changes -> { @access.reload.accessed_at }, from: nil, to: Time.current do
        post card_reading_url(@card), as: :turbo_stream
      end
    end

    assert_response :success
  end

  test "read one notification on card visit" do
    assert_changes -> { @logo_published_notification.reload.read? }, from: false, to: true do
      post card_reading_path(@card), as: :turbo_stream
    end

    assert_response :success
  end

  test "read multiple notifications on card visit" do
    assert_changes -> { @logo_published_notification.reload.read? }, from: false, to: true do
      assert_changes -> { @logo_assignment_notification.reload.read? }, from: false, to: true do
        post card_reading_path(@card), as: :turbo_stream
      end
    end

    assert_response :success
  end

  test "destroy" do
    freeze_time

    @logo_published_notification.read
    @logo_assignment_notification.read

    assert_changes -> { @logo_published_notification.reload.read? }, from: true, to: false do
      assert_changes -> { @access.reload.accessed_at }, to: Time.current do
        delete card_reading_url(@card), as: :turbo_stream
      end
    end

    assert_response :success
  end

  test "unread one notification on destroy" do
    @logo_published_notification.read

    assert_changes -> { @logo_published_notification.reload.read? }, from: true, to: false do
      delete card_reading_path(@card), as: :turbo_stream
    end

    assert_response :success
  end

  test "unread multiple notifications on destroy" do
    @logo_published_notification.read
    @logo_assignment_notification.read

    assert_changes -> { @logo_published_notification.reload.read? }, from: true, to: false do
      assert_changes -> { @logo_assignment_notification.reload.read? }, from: true, to: false do
        delete card_reading_path(@card), as: :turbo_stream
      end
    end

    assert_response :success
  end
end
