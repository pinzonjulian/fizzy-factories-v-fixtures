FactoryBot.define do
  factory :column, class: "Column" do

    trait :writebook_triage do
      name { "Triage" }
      color { "var(--color-card-4)" }
      association :board, :writebook
      position { 0 }
      association :account, :"37s"
    end

    trait :writebook_in_progress do
      name { "In progress" }
      color { "var(--color-card-2)" }
      association :board, :writebook
      position { 1 }
      association :account, :"37s"
    end

    trait :writebook_on_hold do
      name { "On Hold" }
      color { "var(--color-card-4)" }
      association :board, :writebook
      position { 2 }
      association :account, :"37s"
    end

    trait :writebook_review do
      name { "Review" }
      color { "var(--color-card-3)" }
      association :board, :writebook
      position { 3 }
      association :account, :"37s"
    end
  end
end