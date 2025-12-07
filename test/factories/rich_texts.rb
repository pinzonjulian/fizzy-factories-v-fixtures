FactoryBot.define do
  factory :rich_text, class: "RichText" do

    trait :logo_agreement_jz do
      association :account, :"37s"
      association :record, factory: [:comment, :logo_agreement_jz]
      name { "body" }
      body { "I agree." }
    end

    trait :logo_agreement_kevin do
      association :account, :"37s"
      association :record, factory: [:comment, :logo_agreement_kevin]
      name { "body" }
      body { "Same, let's do it." }
    end

    trait :layout_overflowing_david do
      association :account, :"37s"
      association :record, factory: [:comment, :layout_overflowing_david]
      name { "body" }
      body { "The text is overflowing the container." }
    end
  end
end
