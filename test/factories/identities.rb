FactoryBot.define do
  factory :identity, class: "Identity" do

    trait :david do
      email_address { "david@37signals.com" }
      staff { true }
    end

    trait :jz do
      email_address { "jz@37signals.com" }
    end

    trait :jason do
      email_address { "jason@37signals.com" }
      staff { true }
    end

    trait :kevin do
      email_address { "kevin@37signals.com" }
      staff { true }
    end

    trait :mike do
      email_address { "mike@37signals.com" }
    end
  end
end
