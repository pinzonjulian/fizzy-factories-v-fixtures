FactoryBot.define do
  factory :card, class: "Card" do

    trait :logo do
      number { 1 }
      association :board, :writebook
      association :creator, :david
      association :column, :writebook_triage
      title { "The logo isn't big enough" }
      due_on { 3.days.from_now }
      created_at { 1.week.ago }
      status { "published" }
      last_active_at { 1.week.ago }
      association :account, :"37s"
    end

    trait :layout do
      number { 2 }
      association :board, :writebook
      association :creator, :david
      association :column, :writebook_triage
      title { "Layout is broken" }
      created_at { 1.week.ago }
      status { "published" }
      last_active_at { 1.week.ago }
      association :account, :"37s"
    end

    trait :text do
      number { 3 }
      association :board, :writebook
      association :creator, :kevin
      association :column, :writebook_in_progress
      title { "The text is too small" }
      created_at { 1.week.ago }
      status { "published" }
      last_active_at { 1.week.ago }
      association :account, :"37s"
    end

    trait :shipping do
      number { 4 }
      association :board, :writebook
      association :creator, :kevin
      association :column, :writebook_triage
      title { "We need to ship the app" }
      created_at { 1.week.ago }
      status { "published" }
      last_active_at { 1.week.ago }
      association :account, :"37s"
    end

    trait :buy_domain do
      number { 5 }
      association :board, :writebook
      association :creator, :david
      title { "Buy domain" }
      created_at { 1.week.ago }
      status { "published" }
      last_active_at { 1.week.ago }
      association :account, :"37s"
    end

    trait :radio do
      number { 1 }
      association :board, :miltons_wish_list
      association :creator, :mike
      title { "I want to play my radio at a reasonable volume" }
      created_at { 1.week.ago }
      status { "published" }
      last_active_at { 1.week.ago }
      association :account, :initech
    end

    trait :paycheck do
      number { 2 }
      association :board, :miltons_wish_list
      association :creator, :mike
      title { "I haven't received my paycheck" }
      created_at { 1.week.ago }
      status { "published" }
      last_active_at { 1.week.ago }
      association :account, :initech
    end
  end
end
