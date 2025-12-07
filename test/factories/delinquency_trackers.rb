FactoryBot.define do
  factory :delinquency_tracker, class: "DelinquencyTracker" do

    trait :active_webhook_tracker do
      association :account, :"37s"
      association :webhook, :active
      consecutive_failures_count { 1 }
      first_failure_at { 1.hour.ago }
    end

    trait :inactive_webhook_tracker do
      association :account, :"37s"
      association :webhook, :inactive
      consecutive_failures_count { 1 }
      first_failure_at { 1.hour.ago }
    end
  end
end
