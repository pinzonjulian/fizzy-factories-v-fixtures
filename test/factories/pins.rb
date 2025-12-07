FactoryBot.define do
  factory :pin, class: "Pin" do

    trait :logo_kevin do
      association :account, :"37s"
      association :card, :logo
      association :user, :kevin
    end

    trait :shipping_kevin do
      association :account, :"37s"
      association :card, :shipping
      association :user, :kevin
    end
  end
end