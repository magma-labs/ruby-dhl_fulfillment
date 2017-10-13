# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DHL::Fulfillment::APICaller do
  let(:token_store) { double }
  let(:caller) { DHL::Fulfillment::APICaller.new(token_store) }
  let(:response_body) { '' }
  let(:response) { double('response') }

  before do
    allow(token_store).to receive(:api_token) { 'access-token' }
    allow(token_store).to receive(:clear)
    allow(response).to receive(:body) { response_body }
    allow(response).to receive(:to_s) { response_body }
  end

  describe '#call' do
    context 'when the response has a successful status' do
      before do
        allow(RestClient::Request).to receive(:execute) { response }
      end

      it 'raises no errors' do
        expect { caller.call(method: :get, url: '/test-url') }.not_to raise_error
      end
    end

    context 'when the response has a 400 Bad Request status code' do
      let(:response_body) { '{"error": {"description": "A problem ocurred", "detailError": ""}}' }

      before do
        allow(response).to receive(:code) { 400 }
        allow(RestClient::Request).to receive(:execute).and_raise RestClient::Exception, response
      end

      it 'raises a DHL::Fulfillment::APIException with a related message' do
        expect { caller.call(method: :get, url: '/test-url') }
            .to raise_error DHL::Fulfillment::APIException
      end
    end

    context 'when the response has a 401 Unauthorized status code' do
      before do
        allow(RestClient::Request).to receive(:execute).and_raise RestClient::Unauthorized
      end

      it 'raises a DHL::Fulfillment::Unauthorized' do
        expect { caller.call(method: :get, url: '/test-url') }
            .to raise_error DHL::Fulfillment::Unauthorized
      end
    end

    context 'when the request has an error' do
      let(:response_body) { '{}' }

      before do
        allow(response).to receive(:code) { 500 }
        allow(RestClient::Request).to receive(:execute).and_raise RestClient::Exception, response
      end

      it 'raises a DHL::Fulfillment::APIException with a related message' do
        expect { caller.call(method: :get, url: '/test-url') }
            .to raise_error DHL::Fulfillment::APIException
      end
    end
  end
end
