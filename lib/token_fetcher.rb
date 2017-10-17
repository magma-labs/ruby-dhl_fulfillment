# frozen_string_literal: true

module DHL
  module Fulfillment
    # API Token store
    # :reek:Attribute
    class TokenFetcher
      attr_writer :api_token
      attr_accessor :token_store

      def initialize(username, password, url)
        @username = username
        @password = password
        @url = url
      end

      # :reek:NilCheck
      def api_token
        @api_token ||= begin
          token = token_store&.token
          return token if token.present?

          token = retrieve_token_from_api
          token_store&.token = token
          token
        end
      end

      def clear
        @api_token = nil
      end

      protected

      def retrieve_token_from_api
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
