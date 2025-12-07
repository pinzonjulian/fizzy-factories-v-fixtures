FactoryBot.define do
  factory :assignees_filter, class: "AssigneesFilter" do
    trait :jz_assignments_jz do
      association :assignee, :jz
      association :filter, :jz_assignments
    end
  end
end
