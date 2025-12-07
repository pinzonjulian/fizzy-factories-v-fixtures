FactoryBot.define do
  factory :watch, class: "Watch" do

    trait :logo_david do
      association :account, :"37s"
      association :card, :logo
      association :user, :david
      watching { true }
    end

    trait :logo_kevin do
      association :account, :"37s"
      association :card, :logo
      association :user, :kevin
      watching { true }
    end

    trait :layout_david do
      association :account, :"37s"
      association :card, :layout
      association :user, :david
      watching { true }
    end

    trait :layout_kevin do
      association :account, :"37s"
      association :card, :layout
      association :user, :kevin
      watching { true }
    end

    trait :text_david do
      association :account, :"37s"
      association :card, :text
      association :user, :david
      watching { true }
    end

    trait :text_jz do
      association :account, :"37s"
      association :card, :text
      association :user, :jz
      watching { true }
    end

    trait :shipping_david do
      association :account, :"37s"
      association :card, :shipping
      association :user, :david
      watching { true }
    end

    trait :shipping_jz do
      association :account, :"37s"
      association :card, :shipping
      association :user, :jz
      watching { true }
    end

    trait :shipping_kevin do
      association :account, :"37s"
      association :card, :shipping
      association :user, :kevin
      watching { true }
    end
  end
end
