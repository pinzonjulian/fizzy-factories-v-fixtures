FactoryBot.define do
  factory :engagement, class: "Engagement" do

    trait :logo do
      association :account, :"37s"
      association :card, :logo
    end
  end
end
