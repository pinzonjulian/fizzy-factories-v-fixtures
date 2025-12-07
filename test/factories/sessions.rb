FactoryBot.define do
  factory :session, class: "Session" do

    trait :david do
      association :identity, :david
    end

    trait :kevin do
      association :identity, :kevin
    end

    trait :jz do
      association :identity, :jz
    end

    trait :jason do
      association :identity, :jason
    end

    trait :mike do
      association :identity, :mike
    end
  end
end
