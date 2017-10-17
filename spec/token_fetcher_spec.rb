# frozen_string_literal: true

require 'spec_helper'
require 'webmock/rspec'

RSpec.describe DHL::Fulfillment::TokenFetcher do
  let(:url) { DHL::Fulfillment::Urls::Sandbox.new.token_get }
  subject { DHL::Fulfillment::TokenFetcher.new('username', 'password', url) }

  # Token string from vcr cassette
  let(:token_string) { 'hvCku9Rs2EQz5pJUFqBHENtHMElnF1FK0TQ68FYzkSCUUfy4gzrU7R' }

  describe '#api_token' do
    it 'asks the API for an access token' do
      VCR.use_cassette 'dhl/accesstoken-success' do
        expect(subject.api_token).to eql token_string
      end
    end

    it 'uses base64 encoding to encode credentials' do
      expect(Base64).to receive_message_chain :encode64, :delete

      VCR.use_cassette('dhl/accesstoken-success') { subject.api_token }
    end

    context 'after obtaining an api token' do
      before do
        VCR.use_cassette('dhl/accesstoken-success') { subject.api_token }
      end

      it 'reuses it' do
        expect(subject.api_token).to eql token_string
        # There should be no HTTP requests issued in this test
        expect(a_request(:any, '*')).not_to have_been_made
      end
    end

    context 'when wrong credentials are provided' do
      it 'raises an api exception' do
        VCR.use_cassette 'dhl/accesstoken-unauthorized', allow_playback_repeats: true do
          expect { subject.api_token }.to raise_error DHL::Fulfillment::APIException
        end
      end
    end
  end

  describe '#clear' do
    before do
      VCR.use_cassette('dhl/accesstoken-success') { subject.api_token }
      allow(subject).to receive(:retrieve_token_from_api) { 'new_token' }
    end

    it 'deletes the stored api token, so a new token is retrieved next time #api_token is called' do
      expect { subject.clear }.to change(subject, :api_token).from(token_string).to('new_token')
    end
  end

  describe '#token_store=' do
    context 'when setting a custom token store' do
      let(:token_store) { double 'token store' }

      before do
        allow(token_store).to receive(:token) { 'token123' }
        allow(token_store).to receive(:token=)
        subject.token_store = token_store
      end

      it 'uses the store to access a stored token' do
        expect(subject.api_token).to eql 'token123'
        expect(token_store).to have_received(:token).once
      end

      context 'when the store doesnt have a token' do
        before do
          allow(token_store).to receive(:token) { nil }
          allow(subject).to receive(:retrieve_token_from_api) { 'token123' }
          subject.api_token
        end

        it 'retrieves the token from the API' do
          expect(subject).to have_received(:retrieve_token_from_api).once
        end

        it 'stores the token in the store' do
          expect(token_store).to have_received(:token=).with('token123').once
        end
      end
    end
  end
end
