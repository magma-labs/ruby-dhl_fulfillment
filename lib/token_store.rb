
# frozen_string_literal: true

module DHL
  module Fulfillment
    # API Token store
    class TokenStore
      include Retry

      def initialize(username, password, urls)
        @username = username
        @password = password
        @urls = urls
      end

      def api_token
        @api_token ||= attempt(3).times { try_retrieve_token }
      rescue Retry::OutOfAttempts
        ExceptionUtils.raise_unauthorized
      end

      def clear
        @api_token = nil
      end

      protected

      def try_retrieve_token
        response = RestClient.get(@urls.token_get, Authorization: "Basic #{encode_credentials}")
        JSON.parse(response.body)['access_token']
      rescue RestClient::Forbidden, RestClient::Unauthorized
        next_try!
      end

      def encode_credentials
        Base64.encode64("#{@username}:#{@password}").delete("\n")
      end
    end
  end
end
