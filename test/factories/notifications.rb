FactoryBot.define do
  factory :notification, class: "Notification" do

    trait :logo_published_kevin do
      association :user, :kevin
      association :source, factory: [:event, :logo_published]
      created_at { 1.week.ago }
      association :creator, factory: [:user, :david]
      association :account, :"37s"
    end

    trait :logo_assignment_kevin do
      association :user, :kevin
      association :source, factory: [:event, :logo_assignment_km]
      created_at { 1.week.ago }
      association :creator, factory: [:user, :david]
      association :account, :"37s"
    end

    trait :layout_commented_kevin do
      association :user, :kevin
      association :source, factory: [:event, :layout_commented]
      created_at { 1.week.ago }
      association :creator, factory: [:user, :david]
      association :account, :"37s"
    end

    trait :logo_card_david_mention_by_jz do
      association :user, :david
      association :source, factory: [:mention, :logo_card_david_mention_by_jz]
      created_at { 1.week.ago }
      association :creator, factory: [:user, :david]
      association :account, :"37s"
    end

    trait :logo_comment_david_mention_by_jz do
      association :user, :david
      association :source, factory: [:mention, :logo_comment_david_mention_by_jz]
      created_at { 1.week.ago }
      association :creator, factory: [:user, :david]
      association :account, :"37s"
    end

  end
end
