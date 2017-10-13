# frozen_string_literal: true

module DHL
  module Fulfillment
    # Helps converting the RestClient exceptions to DHL API Exceptions
    class ExceptionUtils
      class << self
        def handle_error_rethrow
          yield
        rescue RestClient::BadRequest => exception
          bad_request(exception)
        rescue RestClient::Unauthorized
          raise_unauthorized
        rescue RestClient::Exception => exception
          raise_generic_error(exception.message, exception.response.body)
        end

        def bad_request(exception)
          message = ensure_error_message(exception) do |response|
            error = response['error']
            "#{error['description']}: #{error['detailError']}"
          end
          raise APIException.new(message, exception.response.body)
        end

        def raise_generic_error(message, api_response)
          raise APIException.new(message, api_response)
        end

        def raise_unauthorized
          raise Unauthorized, 'Invalid access token. Verify your credentials.'
        end

        protected

        def ensure_error_message(exception)
          response = JSON.parse(exception.response.body)
          yield response
        rescue NoMethodError
          exception.message
        end
      end
    end
  end
end
