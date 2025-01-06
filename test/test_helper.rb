ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "vcr"
require "minitest/mock"
require 'webmock/minitest'

# VCR configuration
VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
end

class ActiveSupport::TestCase
  include ActiveJob::TestHelper
  
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Explicitly list only the fixtures we need
  fixtures :books, :topics

  setup do
    # Clear any jobs before each test
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = false
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = false

    # Configure memory store for caching in tests
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  # Add more helper methods to be used by all tests here...
  def stub_service_call(service, method, return_value)
    service.stub method, return_value do
      yield
    end
  end
end
