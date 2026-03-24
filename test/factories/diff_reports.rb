FactoryBot.define do
  factory :diff_report do
    snapshot_a { nil }
    snapshot_b { nil }
    diff_data { "MyText" }
    summary { "MyString" }
  end
end
