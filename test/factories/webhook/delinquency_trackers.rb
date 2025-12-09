FactoryBot.define do
  factory :webhook_delinquency_tracker, class: "Webhook::DelinquencyTracker" do
    association :webhook, :active
    consecutive_failures_count { 0 }
    first_failure_at { nil }
  end
end
