require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @david = create(:user, :david, account: @account)
    @kevin = create(:user, :kevin, account: @account)
    @jz = create(:user, :jz, account: @account)
    @jason = create(:user, :jason, account: @account)
  end

  test "show" do
    sign_in_as @kevin

    get user_path(@david)
    assert_in_body @david.name
  end

  test "update oneself" do
    sign_in_as @kevin

    get edit_user_path(@kevin)
    assert_response :ok

    put user_path(@kevin), params: { user: { name: "New Kevin" } }
    assert_redirected_to user_path(@kevin)
    assert_equal "New Kevin", @kevin.reload.name
  end

  test "update other as admin" do
    sign_in_as @kevin

    get edit_user_path(@david)
    assert_response :ok

    put user_path(@david), params: { user: { name: "New David" } }
    assert_redirected_to user_path(@david)
    assert_equal "New David", @david.reload.name
  end

  test "destroy" do
    sign_in_as @kevin

    assert_difference -> { User.active.count }, -1 do
      delete user_path(@david)
    end

    assert_redirected_to users_path
    assert_nil User.active.find_by(id: @david.id)
  end

  test "admin cannot deactivate the owner" do
    sign_in_as @kevin

    assert @jason.owner?
    assert @jason.active

    assert_no_difference -> { User.active.count } do
      delete user_path(@jason)
    end

    assert_response :forbidden
    assert @jason.reload.active
  end

  test "non-admins cannot perform actions" do
    sign_in_as @jz

    put user_path(@david), params: { user: { role: "admin" } }
    assert_response :forbidden

    delete user_path(@david)
    assert_response :forbidden
  end

  test "update with invalid avatar shows validation error" do
    sign_in_as @kevin

    svg_file = fixture_file_upload("avatar.svg", "image/svg+xml")

    put user_path(@kevin), params: { user: { avatar: svg_file } }
    assert_response :unprocessable_entity
    assert_select "form[action='#{user_path(@kevin)}']"
    assert_select ".txt-negative", text: /must be a JPEG, PNG, GIF, or WebP image/
  end

  test "update with valid avatar" do
    sign_in_as @kevin

    png_file = fixture_file_upload("avatar.png", "image/png")

    put user_path(@kevin), params: { user: { avatar: png_file } }
    assert_redirected_to user_path(@kevin)
    assert @kevin.reload.avatar.attached?
    assert_equal "image/png", @kevin.avatar.content_type
  end
end
