# frozen_string_literal: true

require 'webmock/rspec'
require 'vcr'
require_relative '../dhl_efulfillment'

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

  config.before :suite do
    DHL::EFulfillment.configure do |config|
      config.client_id = 'dhlclientid'
      config.client_secret = 'dhlclientsecret'
      config.account_number = '123456'
      config.token_api_url = 'https://api-qa.dhlecommerce.com/efulfillment/v1/auth/accesstoken'
      config.order_api_url = 'https://api-qa.dhlecommerce.com/efulfillment/v1/order'
      config.order_acknowledgement_api_url = 'https://api-qa.dhlecommerce.com/efulfillment/v1/order/acknowledgement'
      config.order_status_api_url = 'https://api-qa.dhlecommerce.com/efulfillment/v1/order/status'
      config.order_shipment_details_api_url = 'https://api-qa.dhlecommerce.com/efulfillment/v1/shipment/details'
    end
  end
end
