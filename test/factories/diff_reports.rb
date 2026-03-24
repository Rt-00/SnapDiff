FactoryBot.define do
  factory :diff_report do
    association :snapshot_a, factory: :snapshot
    association :snapshot_b, factory: :snapshot
    diff_data { { added: [], removed: [], changed: [] } }
    summary { "No changes" }
  end
end
