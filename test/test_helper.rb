ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

require "rails/test_help"
require "webmock/minitest"
require "vcr"
require "mocha/minitest"
require "turbo/broadcastable/test_helper"

WebMock.allow_net_connect!

VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = true
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data("<OPEN_AI_KEY>") { Rails.application.credentials.openai_api_key || ENV["OPEN_AI_API_KEY"] }
  config.default_cassette_options = {
    match_requests_on: [ :method, :uri, :body ]
  }

  config.before_record do |i|
    if i.request&.body
      i.request.body.gsub!(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} UTC/, "<TIME>")
    end
  end

  config.register_request_matcher :body_without_times do |r1, r2|
    b1 = (r1.body || "").gsub(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} UTC/, "<TIME>")
    b2 = (r2.body || "").gsub(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} UTC/, "<TIME>")
    b1 == b2
  end

  config.default_cassette_options = {
    match_requests_on: [ :method, :uri, :body_without_times ]
  }
end

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    include Oaken.loader.test_setup
    include ActiveJob::TestHelper
    include ActionTextTestHelper, CardTestHelper, ChangeTestHelper, SessionTestHelper
    include Turbo::Broadcastable::TestHelper

    setup do
      Current.account = accounts._37s
    end

    teardown do
      Current.clear_all
    end
  end
end

class ActionDispatch::IntegrationTest
  setup do
    integration_session.default_url_options[:script_name] = accounts._37s.slug
  end

  private
    def without_action_dispatch_exception_handling
      original = Rails.application.config.action_dispatch.show_exceptions
      Rails.application.config.action_dispatch.show_exceptions = :none
      yield
    ensure
      Rails.application.config.action_dispatch.show_exceptions = original
    end
end

class ActionDispatch::SystemTestCase
  setup do
    self.default_url_options[:script_name] = accounts._37s.slug
  end
end
