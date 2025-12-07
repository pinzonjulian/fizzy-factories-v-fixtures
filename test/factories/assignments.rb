FactoryBot.define do
  factory :assignment, class: "Assignment" do

    trait :logo_jz do
      association :account, :"37s"
      association :assigner, :david
      association :assignee, :jz
      association :card, :logo
      created_at { 1.week.ago }
    end

    trait :logo_kevin do
      association :account, :"37s"
      association :assigner, :david
      association :assignee, :kevin
      association :card, :logo
      created_at { 1.day.ago }
    end

    trait :layout_jz do
      association :account, :"37s"
      association :assigner, :david
      association :assignee, :jz
      association :card, :layout
    end
  end
end
