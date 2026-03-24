require "simplecov"
SimpleCov.start "rails" do
  minimum_coverage 75
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
