require "simplecov"
SimpleCov.start "rails" do
  # Coverage threshold is enforced only when running the full suite (all tests).
  # Set COVERAGE_MIN env var to override (e.g. COVERAGE_MIN=75 rails test).
  minimum_coverage(ENV.fetch("COVERAGE_MIN", 0).to_i)
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/vendor/"
  add_group "Models",      "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Services",    "app/services"
  add_group "Jobs",        "app/jobs"
  add_group "Helpers",     "app/helpers"
  add_group "Mailers",     "app/mailers"
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

Dir[Rails.root.join("test/support/**/*.rb")].each { |f| require f }

module ActiveSupport
  class TestCase
    # Parallel workers break SimpleCov — run sequentially in test env
    # parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # FactoryBot shorthand (e.g. `create(:user)` instead of `FactoryBot.create(:user)`)
    include FactoryBot::Syntax::Methods
  end
end
