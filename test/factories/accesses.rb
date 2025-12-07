FactoryBot.define do
  factory :access, class: "Access" do

    trait :writebook_david do
      association :account, :"37s"
      association :board, :writebook
      association :user, :david
    end

    trait :writebook_jz do
      association :account, :"37s"
      association :board, :writebook
      association :user, :jz
    end

    trait :writebook_kevin do
      association :account, :"37s"
      association :board, :writebook
      association :user, :kevin
    end

    trait :private_kevin do
      association :account, :"37s"
      association :board, :private
      association :user, :kevin
    end
  end
end
