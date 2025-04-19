ENV["RAILS_ENV"] ||= "test"
require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
  add_filter '/db/'
  add_filter '/lib/'
  add_filter '/config/'
  add_filter '/vendor/'
  track_files '{app}/**/*.rb'
end
require_relative "../config/environment"
require "rails/test_help"
require 'mocha/minitest'

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
