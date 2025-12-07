FactoryBot.define do
  factory :join_code, class: "Account::JoinCode" do

    trait :"37s" do
      code { "37S0-5678-9XYZ" }
      usage_count { 0 }
      usage_limit { 10 }
      association :account, :"37s"
    end

    trait :initech do
      code { "INIT-5678-9XYZ" }
      usage_count { 10 }
      usage_limit { 10 }
      association :account, :initech
    end
  end
end