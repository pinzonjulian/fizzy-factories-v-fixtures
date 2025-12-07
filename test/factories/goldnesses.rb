FactoryBot.define do
  factory :goldness, class: "Card::Goldness" do

    trait :logo do
      association :account, :"37s"
      association :card, :logo
    end
  end
end
