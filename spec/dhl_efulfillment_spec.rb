# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DHL::EFulfillment, '#access_token' do
  before(:each) do
    DHL::EFulfillment.configure do |config|
      config.client_id = ENV['DHL_EFULFILLMENT_CLIENT_ID']
      config.client_secret = ENV['DHL_EFULFILLMENT_CLIENT_SECRET']
      config.token_api_url = ENV['DHL_EFULFILLMENT_TOKEN_API_URL']
    end
  end

  describe 'initialized with credentials' do
    it 'raises no errors' do
      VCR.use_cassette('dhl/accesstoken-success') do
        token = nil
        expect { token = DHL::EFulfillment.access_token }.not_to raise_error
        expect(token).not_to be_nil
      end
    end
  end

  context 'when request returns a 403 error' do
    before do
      DHL::EFulfillment.configure do |config|
        config.token_api_url = 'https://api-qa.dhlecommerce.com/efulfillment/v1/auth/no-exists'
      end
    end

    it 'raises an exception' do
      VCR.use_cassette('dhl/accesstoken-forbidden') do
        expect { DHL::EFulfillment.access_token }.to raise_error RestClient::Forbidden
      end
    end
  end

  context 'when credentials are wrong' do
    before do
      DHL::EFulfillment.configure do |config|
        config.client_id = "#{ENV['DHL_EFULFILLMENT_CLIENT_ID']}aa"
        config.client_secret = "#{ENV['DHL_EFULFILLMENT_CLIENT_SECRET']}aa"
      end
    end

    it 'raises an 401 exception' do
      VCR.use_cassette('dhl/accesstoken-unauthorized') do
        expect { DHL::EFulfillment.access_token }.to raise_error RestClient::Unauthorized
      end
    end
  end
end

RSpec.describe DHL::EFulfillment, '#create_order' do
  token = nil
  options = nil

  before(:all) do
    DHL::EFulfillment.configure do |config|
      config.client_id = ENV['DHL_EFULFILLMENT_CLIENT_ID']
      config.client_secret = ENV['DHL_EFULFILLMENT_CLIENT_SECRET']
      config.token_api_url = ENV['DHL_EFULFILLMENT_TOKEN_API_URL']
      config.order_api_url = ENV['DHL_EFULFILLMENT_ORDER_API_URL']
    end

    VCR.use_cassette('dhl/accesstoken-success') do
      token = DHL::EFulfillment.access_token
    end

    options = JSON.parse(File.read("#{File.dirname(__FILE__)}/order_request_body.json"))
  end

  context 'when request is correct' do
    it 'returns a 200 status code' do
      VCR.use_cassette('dhl/create_order_success') do
        expect { DHL::EFulfillment.create_order(options, token) }.not_to raise_error
      end
    end
  end

  context 'when options hash is not in the right format' do
    it 'returns a 400 status code' do
      VCR.use_cassette('dhl/create_order_no_body') do
        expect { DHL::EFulfillment.create_order({}, token) }.to raise_error(/400/)
      end
    end
  end

  context 'when authorization token is not valid' do
    it 'returns a 401 status code' do
      VCR.use_cassette('dhl/create_order_invalid_token') do
        expect { DHL::EFulfillment.create_order(options, 'INVALIDTOKEN') }.to raise_error(/401/)
      end
    end
  end

  context 'when DHL API responds with an "Invalid values for field(s)" error' do
    it 'throws an InvalidValuesFoundForFields error' do
      VCR.use_cassette('dhl/create_order_invalid_fields') do
        expect { DHL::EFulfillment.create_order(options, token) }
            .to raise_error DHL::EFulfillment::InvalidValuesFoundForFields
      end
    end
  end
end

RSpec.describe DHL::EFulfillment, '#order_acknowledgement' do
  token = nil

  before(:all) do
    DHL::EFulfillment.configure do |config|
      config.client_id = ENV['DHL_EFULFILLMENT_CLIENT_ID']
      config.client_secret = ENV['DHL_EFULFILLMENT_CLIENT_SECRET']
      config.order_acknowledgement_api_url = ENV['DHL_EFULFILLMENT_ORDER_AK_API_URL']
      config.account_number = '1111111' # fake account number
    end

    VCR.use_cassette('dhl/accesstoken-success') do
      token = DHL::EFulfillment.access_token
    end
  end

  context 'when request is succesful' do
    it 'returns a 200 status code' do
      VCR.use_cassette('dhl/order_acknowledgement_sucess') do
        params = {
            order_number: '1234',
            order_submission_id: '0420FL011',
            token: token
        }
        expect { DHL::EFulfillment.order_acknowledgement(params) }.not_to raise_error
      end
    end
  end

  context 'when the validation of an order failed' do
    let(:params) { { order_number: '1234', order_submission_id: '0420FL011', token: token } }
    let(:cassete) { 'dhl/order_acknowledgement_error' }

    it 'raises an AcknowledgmentError exception' do
      VCR.use_cassette(cassete) do
        error = DHL::EFulfillment::AcknowledgementError
        expect { DHL::EFulfillment.order_acknowledgement(params) }.to raise_error error
      end
    end
  end
end

RSpec.describe DHL::EFulfillment, '#order_status' do
  token = nil

  before(:all) do
    DHL::EFulfillment.configure do |config|
      config.client_id = ENV['DHL_EFULFILLMENT_CLIENT_ID']
      config.client_secret = ENV['DHL_EFULFILLMENT_CLIENT_SECRET']
      config.order_acknowledgement_api_url = ENV['DHL_EFULFILLMENT_ORDER_AK_API_URL']
      config.account_number = '1111111' # fake account number
    end

    VCR.use_cassette('dhl/accesstoken-success') do
      token = DHL::EFulfillment.access_token
    end
  end

  context 'when request is succesful' do
    it 'returns a 200 status code' do
      VCR.use_cassette('dhl/order_status_success') do
        expect { DHL::EFulfillment.order_status('1111111', token) }.not_to raise_error
      end
    end
  end

  context 'when the order does not exist' do
    it 'returns a 400 status code' do
      VCR.use_cassette('dhl/order_status_non_existent_order') do
        expect { DHL::EFulfillment.order_status('1111111', token) }.to raise_error(/400/)
      end
    end
  end

  context 'when authorization token is not valid' do
    it 'returns a 401 status code' do
      VCR.use_cassette('dhl/order_status_invalid_token') do
        expect { DHL::EFulfillment.order_status('1111111', 'INVALIDTOKEN') }.to raise_error(/401/)
      end
    end
  end
end

RSpec.describe DHL::EFulfillment, '#order_shipment_details' do
  token = nil

  before(:all) do
    DHL::EFulfillment.configure do |config|
      config.client_id = ENV['DHL_EFULFILLMENT_CLIENT_ID']
      config.client_secret = ENV['DHL_EFULFILLMENT_CLIENT_SECRET']
      config.order_acknowledgement_api_url = ENV['DHL_EFULFILLMENT_ORDER_AK_API_URL']
      config.account_number = '1111111' # fake account number
    end

    VCR.use_cassette('dhl/accesstoken-success') do
      token = DHL::EFulfillment.access_token
    end
    token = 'RtTIvLT4ucEWQ3hGf7Tny7TzvT9qi3mAVgi27e8tIb2FWJifGJt2nf'
  end

  context 'when request is succesful' do
    it 'returns a 200 status code' do
      VCR.use_cassette('dhl/order_shipment_detail_success') do
        expect { DHL::EFulfillment.order_shipment_details('1111111', token) }.not_to raise_error
      end
    end
  end

  context 'when the order does not exist' do
    it 'returns a 400 status code' do
      VCR.use_cassette('dhl/order_shipment_non_existent_order') do
        expect { DHL::EFulfillment.order_shipment_details('1111111', token) }.to raise_error(/400/)
      end
    end
  end

  context 'when authorization token is not valid' do
    it 'returns a 401 status code' do
      VCR.use_cassette('dhl/order_shipment_invalid_token') do
        itoken = 'INVALIDTOKEN'
        expect { DHL::EFulfillment.order_shipment_details('1111111', itoken) }.to raise_error(/401/)
      end
    end
  end
end
