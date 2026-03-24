FactoryBot.define do
  factory :endpoint do
    project { nil }
    name { "MyString" }
    url { "MyString" }
    http_method { "MyString" }
    headers { "MyText" }
    body { "MyText" }
    schedule { "MyString" }
    baseline_snapshot_id { 1 }
  end
end
