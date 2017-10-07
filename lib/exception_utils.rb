# frozen_string_literal: true

require_relative 'exceptions/dhl_api_exception'

module DHL
  module Fulfillment
    # Helps converting the RestClient exceptions to DHL API Exceptions
    class ExceptionUtils
      def self.bad_request(exception)
        message = ensure_error_message(exception) do |response|
          error = response['error']
          "#{error['description']}: #{error['detailError']}"
        end
        raise DHLAPIException.new("[400] #{message}", exception.response.body)
      end

      def self.unauthorized(exception)
        message = ensure_error_message(exception) do |response|
          response['error_description'] || response['reasons']
        end
        raise DHLAPIException.new("[401] #{message}", exception.response.body)
      end

      def self.broken_connection(exception)
        raise DHLAPIException.new("Broken connection: #{message}", exception.response.body)
      end

      def self.handle_error_rethrow
        yield
      rescue RestClient::Unauthorized => exception
        ExceptionUtils.unauthorized(exception)
      rescue RestClient::BadRequest => exception
        ExceptionUtils.bad_request(exception)
      rescue RestClient::ServerBrokeConnection => exception
        ExceptionUtils.broken_connection(exception)
      end

      def self.ensure_error_message(exception)
        response = JSON.parse(exception.response)
        yield response
      rescue NoMethodError
        exception.message
      end

      private_class_method :ensure_error_message
    end
  end
end
