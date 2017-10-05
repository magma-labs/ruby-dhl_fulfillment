# frozen_string_literal: true

require 'base64'
require 'uri'
require 'net/http'
require 'json'
require 'rest-client'
require_relative 'exceptions/acknowledgement_error'
require_relative 'exceptions/already_in_system'
require_relative 'exception_utils'

module DHL
  # :reek:FeatureEnvy
  # Connector for the DHL Fulfillment API (https://api-qa.dhlecommerce.com/efulfillment)
  module EFulfillment
    ALREADY_IN_SYSTEM = 'YFC0001'
    INVALID_VALUES_FOR_FIELDS = '919'

    class << self
      # :reek:Attribute
      attr_accessor :client_id,
                    :client_secret,
                    :account_number,
                    :token_api_url,
                    :order_api_url,
                    :order_status_api_url,
                    :order_shipment_details_api_url,
                    :order_acknowledgement_api_url

      attr_reader :urls

      def configure
        yield self
      end

      def urls=(urls_class)
        @urls = if urls_class.is_a?(Symbol) || urls_class.is_a?(String)
                  "DHL::EFulfillment::Urls::#{urls_class.to_s.camelize}".constantize.new
                else
                  urls_class
                end
      end

      def access_token
        digest = Base64.encode64("#{@client_id}:#{@client_secret}").delete("\n")
        res = RestClient.get @urls.token_get, Authorization: "Basic #{digest}"
        JSON.parse(res.body)['access_token']
      end

      def create_order(options, token)
        ExceptionUtils.handle_error_rethrow do
          headers = request_headers token
          response = RestClient.post @urls.order_create, options.to_json, headers
          raise InvalidValuesFoundForFields if invalid_fields_error?(response)
          response
        end
      end

      def order_acknowledgement(params)
        ExceptionUtils.handle_error_rethrow do
          url = order_acknowledgement_url(params)
          headers = request_headers params[:token]
          response = RestClient.get url, headers
          order_number = params[:order_number]
          raise AlreadyInSystem, order_number, response.body if already_in_system?(response)
          raise AcknowledgementError, response.body if acknowledgement_errors?(response)
          response
        end
      end

      def order_status(order_number, token)
        ExceptionUtils.handle_error_rethrow do
          url = order_status_url(order_number)
          headers = request_headers token
          RestClient.get url, headers
        end
      end

      def order_shipment_details(order_number, token)
        ExceptionUtils.handle_error_rethrow do
          url = shipment_details_url(order_number)
          headers = request_headers token
          RestClient.get url, headers
        end
      end

      protected

      def order_acknowledgement_url(params)
        order_number = params[:order_number]
        order_submission_id = params[:order_submission_id]
        "#{@urls.order_acknowledgement}/#{@account_number}/#{order_number}/#{order_submission_id}"
      end

      def order_status_url(order_number)
        "#{@urls.order_status}/#{@account_number}?orderNumber=#{order_number}"
      end

      def shipment_details_url(order_number)
        "#{@urls.shipment_details}/#{@account_number}?orderNumber=#{order_number}"
      end

      def already_in_system?(response)
        api_errors(response).any? { |error| error['ErrorCode'] == ALREADY_IN_SYSTEM }
      end

      def acknowledgement_errors?(response)
        api_errors(response).count.positive?
      end

      def api_errors(response)
        payload = JSON.parse(response.body)
        payload.dig('CreationAcknowledge', 'Order', 'OrderSubmission', 'Error') || []
      end

      def request_headers(token)
        {
            Authorization: "Bearer #{token}",
            Accept: 'application/json',
            'Content-Type' => 'application/json'
        }
      end

      def invalid_fields_error?(response)
        payload = JSON.parse(response.body)
        payload.dig('error', 'code') == INVALID_VALUES_FOR_FIELDS
      end
    end
  end
end
