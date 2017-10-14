# frozen_string_literal: true

module DHL
  module Fulfillment
    # Makes HTTP requests and transforms internal exceptions to DHL::Fulfillment exceptions
    class APICaller
      API_TIMEOUT = 10

      def initialize(token_store)
        @token_store = token_store
        @method = nil
        @url = nil
        @body = nil
      end

      def call(method:, url:, body: nil, &block)
        store_request_vars(method, url, body)
        response = execute_api_request(&block)
        store_request_vars(nil, nil, nil)
        response
      end

      protected

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
