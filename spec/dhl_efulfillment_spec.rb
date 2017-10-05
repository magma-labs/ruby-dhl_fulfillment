# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DHL::EFulfillment do
  let(:urls) { subject::Urls::Sandbox.new }
  let(:account_number) { '1111111' }
  let(:token) do
    VCR.use_cassette('dhl/accesstoken-success') { return subject.access_token }
  end

  before(:each) do
    subject.configure { |config| config.urls = urls }
  end

  describe '#access_token' do
    describe 'initialized with credentials' do
      it 'raises no errors' do
        expect(token).not_to be_nil
      end
    end

    context 'when request returns a 403 error' do
      before do
        allow(urls).to receive(:token_get) do
          'https://api-qa.dhlecommerce.com/efulfillment/v1/auth/no-exists'
        end
      end

      it 'raises an exception' do
        VCR.use_cassette('dhl/accesstoken-forbidden') do
          expect { subject.access_token }.to raise_error RestClient::Forbidden
        end
      end
    end

    context 'when credentials are wrong' do
      it 'raises an 401 exception' do
        VCR.use_cassette('dhl/accesstoken-unauthorized') do
          expect { subject.access_token }.to raise_error RestClient::Unauthorized
        end
      end
    end
  end

  describe '#create_order' do
    let(:options) { JSON.parse(File.read("#{File.dirname(__FILE__)}/order_request_body.json")) }

    context 'when request is correct' do
      it 'returns a 200 status code' do
        VCR.use_cassette('dhl/create_order_success') do
          expect { subject.create_order(options, token) }.not_to raise_error
        end
      end
    end

    context 'when options hash is not in the right format' do
      it 'returns a 400 status code' do
        VCR.use_cassette('dhl/create_order_no_body') do
          expect { subject.create_order({}, token) }.to raise_error(/400/)
        end
      end
    end

    context 'when authorization token is not valid' do
      it 'returns a 401 status code' do
        VCR.use_cassette('dhl/create_order_invalid_token') do
          expect { subject.create_order(options, 'INVALIDTOKEN') }.to raise_error(/401/)
        end
      end
    end

    context 'when DHL API responds with an "Invalid values for field(s)" error' do
      it 'throws an InvalidValuesFoundForFields error' do
        VCR.use_cassette('dhl/create_order_invalid_fields') do
          expect { subject.create_order(options, token) }
              .to raise_error subject::InvalidValuesFoundForFields
        end
      end
    end
  end

  describe '#order_acknowledgement' do
    context 'when request is succesful' do
      it 'returns a 200 status code' do
        VCR.use_cassette('dhl/order_acknowledgement_sucess') do
          params = {
              order_number: '1234',
              order_submission_id: '0420FL011',
              token: token
          }
          expect { subject.order_acknowledgement(params) }.not_to raise_error
        end
      end
    end

    context 'when the validation of an order failed' do
      let(:params) { { order_number: '1234', order_submission_id: '0420FL011', token: token } }
      let(:cassete) { 'dhl/order_acknowledgement_error' }

      it 'raises an AcknowledgmentError exception' do
        VCR.use_cassette(cassete) do
          error = subject::AcknowledgementError
          expect { subject.order_acknowledgement(params) }.to raise_error error
        end
      end
    end
  end

  describe '#order_status' do
    context 'when request is succesful' do
      it 'returns a 200 status code' do
        VCR.use_cassette('dhl/order_status_success') do
          expect { subject.order_status(account_number, token) }.not_to raise_error
        end
      end
    end

    context 'when the order does not exist' do
      it 'returns a 400 status code' do
        VCR.use_cassette('dhl/order_status_non_existent_order') do
          expect { subject.order_status(account_number, token) }.to raise_error(/400/)
        end
      end
    end

    context 'when authorization token is not valid' do
      it 'returns a 401 status code' do
        VCR.use_cassette('dhl/order_status_invalid_token') do
          expect { subject.order_status(account_number, 'INVALIDTOKEN') }.to raise_error(/401/)
        end
      end
    end
  end

  describe '#order_shipment_details' do
    context 'when request is succesful' do
      it 'returns a 200 status code' do
        VCR.use_cassette('dhl/order_shipment_detail_success') do
          expect { subject.order_shipment_details(account_number, token) }.not_to raise_error
        end
      end
    end

    context 'when the order does not exist' do
      it 'returns a 400 status code' do
        VCR.use_cassette('dhl/order_shipment_non_existent_order') do
          expect { subject.order_shipment_details(account_number, token) }.to raise_error(/400/)
        end
      end
    end

    context 'when authorization token is not valid' do
      it 'returns a 401 status code' do
        VCR.use_cassette('dhl/order_shipment_invalid_token') do
          itoken = 'INVALIDTOKEN'
          expect { subject.order_shipment_details(account_number, itoken) }.to raise_error(/401/)
        end
      end
    end
  end
end
