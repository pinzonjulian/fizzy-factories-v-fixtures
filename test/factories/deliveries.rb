FactoryBot.define do
  factory :delivery, class: "Delivery" do

    trait :successfully_completed do
      association :account, :"37s"
      association :webhook, :active
      association :event, :logo_published
      state { "completed" }
      request { { headers: {} }.to_json }
      response { { code: 200, headers: {} }.to_json }
      created_at { 1.week.ago }
    end

    trait :unsuccessfully_completed do
      association :account, :"37s"
      association :webhook, :active
      association :event, :logo_assignment_jz
      state { "completed" }
      request { { headers: {} }.to_json }
      response { { code: 422, headers: {} }.to_json }
      created_at { 1.week.ago + 1.hour }
    end

    trait :errored do
      association :account, :"37s"
      association :webhook, :active
      association :event, :layout_published
      state { "errored" }
      request { { headers: {} }.to_json }
      response { { error: "destination_unreachable" }.to_json }
      created_at { 1.week.ago }
    end

    trait :pending do
      association :account, :"37s"
      association :webhook, :active
      association :event, :shipping_closed
      state { "pending" }
      request { nil }
      response { nil }
      created_at { 2.days.ago }
    end

    trait :in_progress do
      association :account, :"37s"
      association :webhook, :active
      association :event, :logo_assignment_km
      state { "in_progress" }
      request { nil }
      response { nil }
      created_at { 1.day.ago }
    end
  end
end
