require "test_helper"

class Users::AvatarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Current.account
    @david = create(:user, :david, account: @account)
    @kevin = create(:user, :kevin, account: @account)
    @system = create(:user, :system, account: @account)
    sign_in_as @david
  end

  test "show system user" do
    get user_avatar_path(@system)

    assert_response :redirect
    assert_redirected_to ActionController::Base.helpers.image_path("system_user.png")
  end

  test "show own initials without caching" do
    get user_avatar_path(@david)
    assert_match "image/svg+xml", @response.content_type
    assert @response.cache_control[:private]
    assert_equal "0", @response.cache_control[:max_age]
  end

  test "show other initials with caching" do
    get user_avatar_path(@kevin)
    assert_match "image/svg+xml", @response.content_type
    assert @response.cache_control[:private]
    assert_equal 30.minutes.to_s, @response.cache_control[:max_age]
  end

  test "show own image redirects to the blob url" do
    @david.avatar.attach(io: File.open(file_fixture("moon.jpg")), filename: "moon.jpg", content_type: "image/jpeg")
    assert @david.avatar.attached?

    get user_avatar_path(@david)

    assert_redirected_to rails_blob_url(@david.avatar_thumbnail, disposition: "inline")
  end

  test "show other image redirects to the blob url" do
    @kevin.avatar.attach(io: File.open(file_fixture("moon.jpg")), filename: "moon.jpg", content_type: "image/jpeg")
    assert @kevin.avatar.attached?

    get user_avatar_path(@kevin)

    assert_redirected_to rails_blob_url(@kevin.avatar_thumbnail, disposition: "inline")
  end

  test "delete self" do
    delete user_avatar_path(@david)
    assert_redirected_to @david
  end

  test "unable to delete other" do
    delete user_avatar_path(@kevin)
    assert_response :forbidden
  end
end
