FactoryBot.define do
  factory :account, class: "Account" do

    trait :"37s" do
      name { "37signals" }
      cards_count { 5 }
    end

    trait :initech do
      name { "Initech LLC" }
      cards_count { 0 }
    end
  end
end
