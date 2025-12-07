FactoryBot.define do
  factory :filters_tag, class: "FiltersTag" do
    trait :jz_assignments_mobile do
      association :filter, :jz_assignments
      association :tag, :mobile
    end
  end
end
