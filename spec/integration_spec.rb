# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'The DHL Fulfillment gem' do
  subject { DHL::Fulfillment }
  let(:account_number) { '1111111' }
  let(:urls) { DHL::Fulfillment::Urls::Sandbox.new }
  let(:token_store) { DHL::Fulfillment::TokenStore.new('username', 'password', urls.token_get) }
  let(:api_caller) { DHL::Fulfillment::APICaller.new(token_store) }

  before(:each) do
    DHL::Fulfillment.configure do |config|
      config.urls = urls
      config.api_caller = api_caller
    end
  end

  describe '#create_sales_order' do
    let(:properties) { JSON.parse File.read('spec/support/order_request_body.json') }

    context 'when request is correct' do
      it 'returns true' do
        VCR.use_cassette('dhl/accesstoken-success') do
          VCR.use_cassette('dhl/create_order_success') do
            expect(subject.create_sales_order(properties)).to be true
          end
        end
      end
    end

    context 'when properties hash is not in the right format' do
      it 'returns a 400 status code' do
        VCR.use_cassette('dhl/accesstoken-success') do
          VCR.use_cassette('dhl/create_order_no_body') do
            properties = {}
            expect { subject.create_sales_order(properties) }.to raise_error(/400/)
          end
        end
      end
    end

    context 'when authorization token is not valid' do
      it 'returns a 401 status code' do
        VCR.use_cassette('dhl/accesstoken-success', allow_playback_repeats: true) do
          VCR.use_cassette 'dhl/create_order_invalid_token', allow_playback_repeats: true do
            expect { subject.create_sales_order(properties) }
                .to raise_error DHL::Fulfillment::Unauthorized
          end
        end
      end

      it 'resets the store api token, so a new one can be retrieved' do
        allow(token_store).to receive(:clear)

        VCR.use_cassette('dhl/accesstoken-success', allow_playback_repeats: true) do
          VCR.use_cassette 'dhl/create_order_invalid_token', allow_playback_repeats: true do
            expect { subject.create_sales_order(properties) }
                .to raise_error DHL::Fulfillment::Unauthorized
          end
        end

        # store receives this message twice because we attempt twice to do the request
        expect(token_store).to have_received(:clear).twice
      end

      it 'tries again a second time' do
        allow(api_caller).to receive(:execute_api_request).and_raise RestClient::Unauthorized

        expect { subject.create_sales_order(properties) }
            .to raise_error DHL::Fulfillment::Unauthorized
        expect(api_caller).to have_received(:execute_api_request).twice
      end
    end

    context 'when DHL API responds with an "Invalid values for field(s)" error' do
      it 'throws an InvalidValuesFoundForFields error' do
        VCR.use_cassette('dhl/accesstoken-success') do
          VCR.use_cassette('dhl/create_order_invalid_fields') do
            expect { subject.create_sales_order(properties) }
                .to raise_error DHL::Fulfillment::InvalidValuesFoundForFields
          end
        end
      end
    end
  end

  describe '#sales_order_acknowledgement' do
    let(:order_number) { '1234' }
    let(:submission_id) { '0420FL011' }

    context 'when request is succesful' do
      it 'returns a 200 status code' do
        VCR.use_cassette('dhl/accesstoken-success') do
          VCR.use_cassette('dhl/order_acknowledgement_sucess') do
            expect { subject.sales_order_acknowledgement(order_number, submission_id) }
                .not_to raise_error
          end
        end
      end
    end

    context 'when the validation of an order failed' do
      let(:cassete) { 'dhl/order_acknowledgement_error' }

      it 'raises an AcknowledgmentError exception' do
        VCR.use_cassette('dhl/accesstoken-success') do
          VCR.use_cassette(cassete) do
            expect { subject.sales_order_acknowledgement(order_number, submission_id) }
                .to raise_error DHL::Fulfillment::AcknowledgementError
          end
        end
      end
    end
  end

  describe '#sales_order_status' do
    context 'when request is succesful' do
      it 'returns a 200 status code' do
        VCR.use_cassette('dhl/accesstoken-success', allow_playback_repeats: true) do
          VCR.use_cassette('dhl/order_status_success') do
            expect { subject.sales_order_status(account_number) }.not_to raise_error
          end
        end
      end
    end

    context 'when the order does not exist' do
      it 'returns a 400 status code' do
        VCR.use_cassette('dhl/accesstoken-success') do
          VCR.use_cassette 'dhl/order_status_non_existent_order', allow_playback_repeats: true do
            expect { subject.sales_order_status(account_number) }.to raise_error(/400/)
          end
        end
      end
    end

    context 'when authorization token is not valid' do
      it 'raises an Unauthorized exception' do
        VCR.use_cassette('dhl/accesstoken-success', allow_playback_repeats: true) do
          VCR.use_cassette 'dhl/order_status_invalid_token', allow_playback_repeats: true do
            expect { subject.sales_order_status(account_number) }
              .to raise_error DHL::Fulfillment::Unauthorized
          end
        end
      end
    end
  end

  describe '#shipment_details' do
    context 'when request is succesful' do
      it 'returns a 200 status code' do
        VCR.use_cassette('dhl/accesstoken-success') do
          VCR.use_cassette('dhl/order_shipment_detail_success') do
            expect { subject.shipment_details(account_number) }.not_to raise_error
          end
        end
      end
    end

    context 'when the order does not exist' do
      it 'returns a 400 status code' do
        VCR.use_cassette('dhl/accesstoken-success') do
          VCR.use_cassette('dhl/order_shipment_non_existent_order') do
            expect { subject.shipment_details(account_number) }.to raise_error(/400/)
          end
        end
      end
    end

    context 'when authorization token is not valid' do
      it 'raises an Unauthorized exception' do
        VCR.use_cassette('dhl/accesstoken-success', allow_playback_repeats: true) do
          VCR.use_cassette 'dhl/order_shipment_invalid_token', allow_playback_repeats: true do
            expect { subject.shipment_details(account_number) }
                .to raise_error DHL::Fulfillment::Unauthorized
          end
        end
      end
    end
  end
end
