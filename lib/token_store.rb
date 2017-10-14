# frozen_string_literal: true

module DHL
  module Fulfillment
    # API Token store
    class TokenStore
      # :reek:Attribute
      attr_writer :api_token

      def initialize(username, password, url)
        @username = username
        @password = password
        @url = url
      end

      def api_token
        @api_token ||= retrieve_token
      end

      def clear
        @api_token = nil
      end

      protected

      def retrieve_token
        ExceptionUtils.handle_error_rethrow do
          response = RestClient.get(@url, Authorization: "Basic #{encode_credentials}")
          JSON.parse(response.body)['access_token']
        end
      end

      def encode_credentials
        Base64.encode64("#{@username}:#{@password}").delete("\n")
      end
    end
  end
end
