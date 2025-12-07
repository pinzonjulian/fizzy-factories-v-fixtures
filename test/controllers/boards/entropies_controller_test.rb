require "test_helper"

class Boards::EntropiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @kevin = create(:user, :kevin, account: @account)
    @jz = create(:user, :jz, account: @account)
    @board = create(:board, :writebook, account: @account, creator: @kevin)
    create(:entropy, account: @account, container: @board, auto_postpone_period: 90.days.to_i)

    sign_in_as @kevin
  end

  test "update" do
    @board.reload
    assert_no_difference -> { Current.account.entropy.reload.auto_postpone_period } do
      put board_entropy_path(@board, format: :turbo_stream), params: { board: { auto_postpone_period: 123.days } }

      assert_equal 123.days, @board.reload.entropy.auto_postpone_period

      assert_turbo_stream action: :replace, target: dom_id(@board, :entropy)
    end
  end

  test "update requires board admin permission" do
    logout_and_sign_in_as @jz

    original_period = @board.entropy.auto_postpone_period

    put board_entropy_path(@board, format: :turbo_stream), params: { board: { auto_postpone_period: 1.day } }

    assert_response :forbidden
    assert_equal original_period, @board.entropy.reload.auto_postpone_period
  end
end
