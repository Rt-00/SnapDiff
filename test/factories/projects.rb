FactoryBot.define do
  factory :project do
    association :user
    sequence(:name) { |n| "Project #{n}" }
    description { "A test project description" }
  end
end
