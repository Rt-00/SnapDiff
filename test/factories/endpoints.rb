FactoryBot.define do
  factory :endpoint do
    association :project
    sequence(:name) { |n| "Endpoint #{n}" }
    url { "https://api.example.com/users" }
    http_method { "GET" }
    headers { {} }
    body { {} }
    schedule { nil }
    baseline_snapshot_id { nil }
  end
end
