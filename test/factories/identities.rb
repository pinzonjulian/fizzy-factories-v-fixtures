FactoryBot.define do
  factory :identity, class: "Identity" do

    trait :david do
      sequence(:email_address) { |n| "david+#{n}@37signals.com" }
      staff { true }
    end

    trait :jz do
      sequence(:email_address) { |n| "jz+#{n}@37signals.com" }
    end

    trait :jason do
      sequence(:email_address) { |n| "jason+#{n}@37signals.com" }
      staff { true }
    end

    trait :kevin do
      sequence(:email_address) { |n| "kevin+#{n}@37signals.com" }
      staff { true }
    end

    trait :mike do
      sequence(:email_address) { |n| "mike+#{n}@37signals.com" }
    end
  end
end
