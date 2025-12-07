FactoryBot.define do
  factory :entropy, class: "Entropy" do

    trait :"37s_account" do
      association :account, :"37s"
      association :container, factory: [:account, :"37s"]
      auto_postpone_period { 30.days.to_i }
    end

    trait :writebook_board do
      association :account, :"37s"
      association :container, factory: [:board, :writebook]
      auto_postpone_period { 90.days.to_i }
    end

    trait :private_board do
      association :account, :"37s"
      association :container, factory: [:board, :private]
      auto_postpone_period { 30.days.to_i }
    end

    trait :initech_account do
      association :account, :initech
      association :container, factory: [:account, :initech]
      auto_postpone_period { 30.days.to_i }
    end

    trait :miltons_wish_list_board do
      association :account, :initech
      association :container, factory: [:board, :miltons_wish_list]
      auto_postpone_period { 90.days.to_i }
    end
  end
end
