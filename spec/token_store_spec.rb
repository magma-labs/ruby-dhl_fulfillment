# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DHL::Fulfillment::TokenStore do
  let(:urls) { DHL::Fulfillment::Urls::Sandbox.new }
  subject { DHL::Fulfillment::TokenStore.new('username', 'password', urls) }

  describe '#api_token' do
    it 'asks the API for an access token' do
      VCR.use_cassette 'dhl/accesstoken-success' do
        # Token string from vcr cassette
        expect(subject.api_token).to eql 'hvCku9Rs2EQz5pJUFqBHENtHMElnF1FK0TQ68FYzkSCUUfy4gzrU7R'
      end
    end

    it 'uses base64 encoding to encode credentials' do
      expect(Base64).to receive_message_chain :encode64, :delete

      VCR.use_cassette('dhl/accesstoken-success') { subject.api_token }
    end

    context 'when wrong credentials are provided' do
      it 'raises an api exception' do
        VCR.use_cassette 'dhl/accesstoken-unauthorized', allow_playback_repeats: true do
          expect { subject.api_token }.to raise_error DHL::Fulfillment::APIException
        end
      end
    end
  end
end
