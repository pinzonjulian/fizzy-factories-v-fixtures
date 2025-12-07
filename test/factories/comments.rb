FactoryBot.define do
  factory :comment, class: "Comment" do

    trait :logo_1 do
      association :card, :logo
      association :creator, :system
      created_at { 1.week.ago }
      association :account, :"37s"
    end

    trait :logo_agreement_jz do
      association :card, :logo
      association :creator, :jz
      created_at { 2.days.ago }
      association :account, :"37s"
    end

    trait :logo_3 do
      association :card, :logo
      association :creator, :system
      created_at { 1.day.ago }
      association :account, :"37s"
    end

    trait :logo_agreement_kevin do
      association :card, :logo
      association :creator, :kevin
      created_at { 2.hours.ago }
      association :account, :"37s"
    end

    trait :logo_5 do
      association :card, :logo
      association :creator, :system
      created_at { 1.hour.ago }
      association :account, :"37s"
    end

    trait :layout_1 do
      association :card, :layout
      association :creator, :system
      association :account, :"37s"
    end

    trait :layout_overflowing_david do
      association :card, :layout
      association :creator, :david
      association :account, :"37s"
    end

    trait :text_1 do
      association :card, :text
      association :creator, :system
      association :account, :"37s"
    end

    trait :shipping_1 do
      association :card, :shipping
      association :creator, :system
      association :account, :"37s"
    end
  end
end
