require "test_helper"

class Notification::BundleMailerTest < ActionMailer::TestCase
  setup do
    @account = Current.account
    @david_identity = create(:identity, :david)
    create(:session, identity: @david_identity)
    @david = create(:user, :david, account: @account, identity: @david_identity)
    create(:user, :system, account: @account)
    @board = create(:board, :writebook, account: @account, creator: @david)

    @bundle = Notification::Bundle.create!(
      user: @david,
      starts_at: 1.hour.ago,
      ends_at: 1.hour.from_now
    )
  end

  test "renders avatar with initials in span when avatar is not attached" do
    create_notification(@david)

    email = Notification::BundleMailer.notification(@bundle)

    assert_match /<span[^>]*class="avatar"[^>]*>/, email.html_part.body.to_s
    assert_match /#{@david.initials}/, email.html_part.body.to_s
    assert_match /style="background-color: #[A-F0-9]{6};?"/, email.html_part.body.to_s
  end

  test "renders avatar with external image URL when avatar is attached" do
    @david.avatar.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "avatar.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )

    create_notification(@david)

    email = Notification::BundleMailer.notification(@bundle)

    assert_match /<img[^>]*class="avatar"[^>]*>/, email.html_part.body.to_s
    assert_match /<img[^>]*class="avatar"[^>]*src="[^"]*"/, email.html_part.body.to_s
    assert_match /alt="#{@david.name}"/, email.html_part.body.to_s
  end

  private
    def create_notification(user)
      Current.set(user: user) do
        card = Card.create!(
          account: @account,
          board: @board,
          creator: user,
          title: "Test card",
          status: "published",
          last_active_at: 1.week.ago
        )
        event = Event.create!(
          account: @account,
          board: @board,
          creator: user,
          eventable: card,
          action: "card_published",
          created_at: 1.week.ago
        )
        Notification.create!(user: user, creator: user, source: event, created_at: 30.minutes.ago)
      end
    end
end
