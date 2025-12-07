FactoryBot.define do
  factory :mention, class: "Mention" do

    trait :logo_card_david_mention_by_jz do
      association :account, :"37s"
      association :source, factory: [:card, :logo]
      association :mentioner, factory: [:user, :jz]
      association :mentionee, factory: [:user, :david]
    end

    trait :logo_comment_david_mention_by_jz do
      association :account, :"37s"
      association :source, factory: [:comment, :logo_agreement_jz]
      association :mentioner, factory: [:user, :jz]
      association :mentionee, factory: [:user, :david]
    end

  end
end