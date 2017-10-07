
# frozen_string_literal: true

module DHL
  module Fulfillment
    # API Token store
    class TokenStore
      def initialize(username, password, urls)
        @username = username
        @password = password
        @urls = urls
      end

      def api_token
        @api_token ||= begin
          encoded = encode_credentials
          response = RestClient.get(@urls.token_get, Authorization: "Basic #{encoded}")
          JSON.parse(response.body)['access_token']
        end
      end

      protected

      def encode_credentials
        Base64.encode64("#{@username}:#{@password}").delete("\n")
      end
    end
  end
end
