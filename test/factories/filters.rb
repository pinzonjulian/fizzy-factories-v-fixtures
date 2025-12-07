FactoryBot.define do
  factory :filter, class: "Filter" do

    trait :jz_assignments do
      association :creator, :david
      fields { { indexed_by: :all, sorted_by: :newest }.to_json }
      association :account, :"37s"

      transient do
        tag { association :tag, :mobile }
        assignee { association :user, :jz }
      end

      params_digest do
        Filter.digest_params({
          indexed_by: :all,
          sorted_by: :newest,
          tag_ids: [tag.id],
          assignee_ids: [assignee.id]
        })
      end
    end
  end
end
