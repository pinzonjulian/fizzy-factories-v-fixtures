require "test_helper"

class Cards::StepsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @kevin = create(:user, :kevin, account: @account)
    @david = create(:user, :david, account: @account)
    @board = create(:board, :writebook, account: @account, creator: @david)
    @column = create(:column, :writebook_triage, board: @board, account: @account)
    @card = with_current_user(@david) do
      create(:card, :logo, board: @board, column: @column, account: @account, creator: @david)
    end

    sign_in_as @kevin
  end

  test "create" do
    assert_difference -> { @card.steps.count }, +1 do
      post card_steps_path(@card), params: { step: { content: "Research alternatives" } }, as: :turbo_stream
      assert_turbo_stream action: :before, target: dom_id(@card, :new_step)
    end

    assert_equal "Research alternatives", @card.steps.last.content
  end

  test "update" do
    step = @card.steps.create!(content: "Original content")

    assert_changes -> { step.reload.content }, from: "Original content", to: "Updated content" do
      put card_step_path(@card, step), params: { step: { content: "Updated content" } }, as: :turbo_stream
      assert_turbo_stream action: :replace, target: dom_id(step)
    end
  end

  test "destroy" do
    step = @card.steps.create!(content: "Step to delete")

    assert_difference -> { @card.steps.count }, -1 do
      delete card_step_path(@card, step), as: :turbo_stream
      assert_turbo_stream action: :remove, target: dom_id(step)
    end
  end

  test "toggle completion" do
    step = @card.steps.create!(content: "Test step", completed: false)

    # Toggle to completed
    assert_changes -> { step.reload.completed? }, from: false, to: true do
      put card_step_path(@card, step), params: { step: { completed: "1" } }, as: :turbo_stream
      assert_turbo_stream action: :replace, target: dom_id(step)
    end

    # Toggle back to incomplete
    assert_changes -> { step.reload.completed? }, from: true, to: false do
      put card_step_path(@card, step), params: { step: { completed: "0" } }, as: :turbo_stream
      assert_turbo_stream action: :replace, target: dom_id(step)
    end
  end
end
