FactoryBot.define do
  factory :event, class: "Event" do

    trait :logo_published do
      association :creator, factory: [:user, :david]
      association :board, :writebook
      association :eventable, factory: [:card, :logo]
      action { "card_published" }
      created_at { 1.week.ago }
      association :account, :"37s"
    end

    trait :logo_assignment_jz do
      association :creator, factory: [:user, :david]
      association :board, :writebook
      association :eventable, factory: [:card, :logo]
      action { "card_assigned" }
      particulars { { assignee_ids: [ActiveRecord::FixtureSet.identify("jz", :uuid)] }.to_json }
      created_at { 1.week.ago + 1.hour }
      association :account, :"37s"
    end

    trait :logo_assignment_david do
      association :creator, factory: [:user, :david]
      association :board, :writebook
      association :eventable, factory: [:card, :logo]
      action { "card_assigned" }
      particulars { { assignee_ids: [ActiveRecord::FixtureSet.identify("david", :uuid)] }.to_json }
      created_at { 1.week.ago + 1.hour }
      association :account, :"37s"
    end

    trait :logo_assignment_km do
      association :creator, factory: [:user, :david]
      association :board, :writebook
      association :eventable, factory: [:card, :logo]
      action { "card_assigned" }
      particulars { { assignee_ids: [ActiveRecord::FixtureSet.identify("kevin", :uuid)] }.to_json }
      created_at { 1.day.ago }
      association :account, :"37s"
    end

    trait :layout_published do
      association :creator, factory: [:user, :david]
      association :board, :writebook
      association :eventable, factory: [:card, :layout]
      action { "card_published" }
      created_at { 1.week.ago }
      association :account, :"37s"
    end

    trait :layout_commented do
      association :creator, factory: [:user, :david]
      association :board, :writebook
      association :eventable, factory: [:comment, :layout_overflowing_david]
      action { "comment_created" }
      created_at { 1.week.ago }
      association :account, :"37s"
    end

    trait :layout_assignment_jz do
      association :creator, factory: [:user, :david]
      association :board, :writebook
      association :eventable, factory: [:card, :layout]
      action { "card_assigned" }
      particulars { { assignee_ids: [ActiveRecord::FixtureSet.identify("jz", :uuid)] }.to_json }
      created_at { 1.hour.ago }
      association :account, :"37s"
    end

    trait :text_published do
      association :creator, factory: [:user, :kevin]
      association :board, :writebook
      association :eventable, factory: [:card, :text]
      action { "card_published" }
      created_at { 1.week.ago }
      association :account, :"37s"
    end

    trait :shipping_published do
      association :creator, factory: [:user, :kevin]
      association :board, :writebook
      association :eventable, factory: [:card, :shipping]
      action { "card_published" }
      created_at { 1.week.ago }
      association :account, :"37s"
    end

    trait :shipping_closed do
      association :creator, factory: [:user, :kevin]
      association :board, :writebook
      association :eventable, factory: [:card, :shipping]
      action { "card_closed" }
      created_at { 2.days.ago }
      association :account, :"37s"
    end
  end
end