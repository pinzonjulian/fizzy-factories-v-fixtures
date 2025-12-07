FactoryBot.define do
  factory :user_settings, class: "User::Settings" do

    trait :david_settings do
      association :account, :"37s"
      association :user, :david
      bundle_email_frequency { "never" }
    end

    trait :jz_settings do
      association :account, :"37s"
      association :user, :jz
      bundle_email_frequency { "never" }
    end

    trait :kevin_settings do
      association :account, :"37s"
      association :user, :kevin
      bundle_email_frequency { "never" }
    end

    trait :system_settings do
      association :account, :"37s"
      association :user, :system
      bundle_email_frequency { "never" }
    end
  end
end