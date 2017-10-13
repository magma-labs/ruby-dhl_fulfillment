# frozen_string_literal: true

module DHL
  module Fulfillment
    class APICaller
      include Support::Retry

      API_TIMEOUT = 10

      def initialize(token_store)
        @token_store = token_store
      end

      def call(method:, url:, body: nil, &block)
        store_request_vars(method, url, body)
        try_call(&block)
      rescue Support::Retry::OutOfAttempts
        ExceptionUtils.raise_unauthorized
      ensure
        store_request_vars(nil, nil, nil)
      end

      protected

      def try_call(&block)
        attempt(2).times do
          begin
            execute_api_request(&block)
          rescue RestClient::Unauthorized
            @token_store.clear
            next_try!
          end
        end
      end

      def execute_api_request
        ExceptionUtils.handle_error_rethrow do
          response = RestClient::Request.execute method: @method,
                                                 url: @url,
                                                 body: @body,
                                                 headers: request_headers,
                                                 timeout: API_TIMEOUT
          yield(response) if block_given?
        end
      end

      def store_request_vars(method, url, body)
        @method = method
        @url = url
        @body = body
      end

      def request_headers
        {
            'Authorization' => "Bearer #{@token_store.api_token}",
            'Accept'        => 'application/json',
            'Content-Type'  => 'application/json'
        }
      end
    end
  end
end
