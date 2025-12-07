FactoryBot.define do
  factory :tagging, class: "Tagging" do

    trait :logo_web do
      association :account, :"37s"
      association :card, :logo
      association :tag, :web
    end

    trait :layout_web do
      association :account, :"37s"
      association :card, :layout
      association :tag, :web
    end

    trait :layout_mobile do
      association :account, :"37s"
      association :card, :layout
      association :tag, :mobile
    end

    trait :text_mobile do
      association :account, :"37s"
      association :card, :text
      association :tag, :mobile
    end
  end
end
