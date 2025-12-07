FactoryBot.define do
  factory :tag, class: "Tag" do

    trait :web do
      title { "web" }
      association :account, :"37s"
    end

    trait :mobile do
      title { "mobile" }
      association :account, :"37s"
    end
  end
end
