FactoryBot.define do
  factory :user, class: "User", aliases: ["creator"] do

    trait :david do
      name { "David" }
      role { "member" }
      association :identity, :david
      association :account, :"37s"
      verified_at { Time.current }
    end

    trait :jz do
      name { "JZ" }
      role { "member" }
      association :identity, :jz
      association :account, :"37s"
      verified_at { Time.current }
    end

    trait :jason do
      name { "Jason" }
      role { "owner" }
      association :identity, :jason
      association :account, :"37s"
      verified_at { Time.current }
    end

    trait :kevin do
      name { "Kevin" }
      role { "admin" }
      association :identity, :kevin
      association :account, :"37s"
      verified_at { Time.current }
    end

    trait :system do
      name { "System" }
      role { "system" }
      association :account, :"37s"
    end

    trait :mike do
      name { "Mike" }
      role { "admin" }
      association :identity, :mike
      association :account, :initech
      verified_at { Time.current }
    end

    trait :system_initech do
      name { "System" }
      role { "system" }
      association :account, :initech
    end
  end
end
