# frozen_string_literal: true

require 'vcr'
require 'webmock/rspec'
require_relative '../dhl_fulfillment'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  WebMock.disable_net_connect!(allow_localhost: true)

  VCR.configure do |conf|
    conf.cassette_library_dir = 'spec/vcr'
    conf.hook_into :webmock
    conf.allow_http_connections_when_no_cassette = true
  end

  DHL::Fulfillment.configure do |config|
    config.urls = :sandbox
    config.client_id = 'dhlclientid'
    config.client_secret = 'dhlclientsecret'
    config.account_number = '1111111'
  end
end
