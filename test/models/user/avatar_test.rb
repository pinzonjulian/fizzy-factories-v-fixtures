require "test_helper"

class User::AvatarTest < ActiveSupport::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    Current.session = create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)
  end

  test "avatar_thumbnail returns variant for variable images" do
    @david.avatar.attach(io: File.open(file_fixture("moon.jpg")), filename: "moon.jpg", content_type: "image/jpeg")

    assert @david.avatar.variable?
    assert_equal @david.avatar.variant(:thumb).blob, @david.avatar_thumbnail.blob
  end

  test "avatar_thumbnail returns original blob for non-variable images" do
    @david.avatar.attach(io: File.open(file_fixture("avatar.svg")), filename: "avatar.svg", content_type: "image/svg+xml")

    assert_not @david.avatar.variable?
    assert_equal @david.avatar.blob, @david.avatar_thumbnail.blob
  end

  test "allows valid image content types" do
    @david.avatar.attach(io: File.open(file_fixture("moon.jpg")), filename: "test.jpg")

    assert @david.valid?
  end

  test "rejects SVG uploads" do
    @david.avatar.attach(io: File.open(file_fixture("avatar.svg")), filename: "avatar.svg")

    assert_not @david.valid?
    assert_includes @david.errors[:avatar], "must be a JPEG, PNG, GIF, or WebP image"
  end
end
