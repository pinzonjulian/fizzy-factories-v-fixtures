FactoryBot.define do
  factory :board, class: "Board" do

    trait :writebook do
      name { "Writebook" }
      association :creator, :david
      all_access { true }
      association :account, :"37s"
    end

    trait :private do
      name { "Private board" }
      association :creator, :kevin
      all_access { false }
      association :account, :"37s"
    end

    trait :miltons_wish_list do
      name { "Milton's Wish List" }
      association :creator, :mike
      all_access { true }
      association :account, :initech
    end
  end
end