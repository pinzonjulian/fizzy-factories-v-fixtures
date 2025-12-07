FactoryBot.define do
  factory :closure, class: "Closure" do

    trait :shipping do
      association :account, :"37s"
      association :card, :shipping
      association :user, :kevin
    end
  end
end
