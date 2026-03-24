FactoryBot.define do
  factory :snapshot do
    association :endpoint
    response_body { { "id" => 1, "name" => "test" } }
    status_code { 200 }
    response_time_ms { 142 }
    taken_at { Time.current }
    triggered_by { "manual" }
  end
end
