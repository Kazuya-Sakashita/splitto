# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "spec_helper"
require_relative "../config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "committee/rails/test/methods"

Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [
    Rails.root.join("spec/fixtures")
  ]

  config.use_transactional_fixtures = true
  config.filter_rails_from_backtrace!

  config.before(:each, type: :request) do
    host! "localhost"
  end

  config.include Committee::Rails::Test::Methods, type: :request
  config.include FactoryBot::Syntax::Methods
end
