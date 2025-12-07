FactoryBot.define do
  factory :reaction, class: "Reaction" do

    trait :kevin do
      association :account, :"37s"
      content { "👍" }
      association :comment, :logo_agreement_jz
      association :reacter, :kevin
    end

    trait :david do
      association :account, :"37s"
      content { "👍" }
      association :comment, :logo_agreement_jz
      association :reacter, :david
    end

  end
end
