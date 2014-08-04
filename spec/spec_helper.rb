# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require "rspec/rails"

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.default_url_options[:host] = "test.com"

Rails.backtrace_cleaner.remove_silencers!

# Configure capybara for integration testing
require "capybara/rails"
Capybara.default_driver   = :rack_test
Capybara.default_selector = :css

## Gem magic at work here
base_spec_path = File.join(Gem::Specification.find_by_name('social_stream-base').full_gem_path, 'spec/')
# ...in social_stream-base/spec/factories.
Dir[File.join(base_spec_path, 'factories/*.rb')].each {|f| require f}
# ...in social_stream-base/spec/support.
#Dir[File.join(base_spec_path, 'support/**/*.rb')].each {|f| require f}
require File.join(base_spec_path, 'support/cancan.rb')
require File.join(base_spec_path, 'support/devise.rb')
require File.join(base_spec_path, 'support/mock.rb')

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  config.include Devise::TestHelpers, :type => :view
end
