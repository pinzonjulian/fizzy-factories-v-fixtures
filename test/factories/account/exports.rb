FactoryBot.define do
  factory :export, class: "Export" do

    trait :pending_export do
      association :account, :"37s"
      association :user, :david
      status { "pending" }
    end

    trait :completed_export do
      association :account, :"37s"
      association :user, :david
      status { "completed" }
      completed_at { 1.hour.ago }
    end
  end
end
