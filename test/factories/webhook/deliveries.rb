FactoryBot.define do
  factory :webhook_delivery, class: "Webhook::Delivery" do
    association :webhook, :active
    association :event, :layout_commented
    state { "pending" }

    trait :pending do
      state { "pending" }
    end

    trait :successfully_completed do
      state { "completed" }
      response { { code: 200 } }
    end

    trait :errored do
      state { "errored" }
      response { { code: 500 } }
    end
  end
end
