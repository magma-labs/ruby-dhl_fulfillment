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
  # Connector for the DHL Fulfillment API (https://api-qa.dhlecommerce.com/efulfillment)
  module EFulfillment
    ALREADY_IN_SYSTEM = 'YFC0001'
    INVALID_VALUES_FOR_FIELDS = '919'

    @client_id = ENV['DHL_EFULFILLMENT_CLIENT_ID']
    @client_secret = ENV['DHL_EFULFILLMENT_CLIENT_SECRET']
    @account_number = ENV['DHL_EFULFILLMENT_ACCOUNT_NUMBER']
    @token_api_url = ENV['DHL_EFULFILLMENT_TOKEN_API_URL']
    @order_api_url = ENV['DHL_EFULFILLMENT_ORDER_API_URL']
    @order_acknowledgement_api_url = ENV['DHL_EFULFILLMENT_ORDER_AK_API_URL']
    @order_status_api_url = ENV['DHL_EFULFILLMENT_ORDER_STATUS_API_URL']
    @order_shipment_details_api_url = ENV['DHL_EFULFILLMENT_ORDER_SHIPPING_API_URL']

    class << self
      # :reek:Attribute
      attr_accessor :client_id, :client_secret, :token_api_url, :order_api_url,
                    :order_acknowledgement_api_url, :account_number
      def configure
        yield self
      end
    end

    def self.access_token
      digest = Base64.encode64("#{@client_id}:#{@client_secret}").delete("\n")
      res = RestClient.get @token_api_url, Authorization: "Basic #{digest}"
      JSON.parse(res.body)['access_token']
    end

    def self.create_order(options, token)
      ExceptionUtils.handle_error_rethrow do
        headers = request_headers token
        response = RestClient.post @order_api_url, options.to_json, headers
        raise InvalidValuesFoundForFields if invalid_fields_error?(response)
        response
      end
    end

    def self.order_acknowledgement(params)
      ExceptionUtils.handle_error_rethrow do
        url = order_acknowledgement_url(params)
        headers = request_headers params[:token]
        response = RestClient.get url, headers
        raise AlreadyInSystem, params[:order_number], response.body if already_in_system?(response)
        raise AcknowledgementError, response.body if acknowledgement_errors?(response)
        response
      end
    end

    def self.order_status(order_number, token)
      ExceptionUtils.handle_error_rethrow do
        url = order_status_url(order_number)
        headers = request_headers token
        RestClient.get url, headers
      end
    end

    def self.order_shipment_details(order_number, token)
      ExceptionUtils.handle_error_rethrow do
        url = shipment_details_url(order_number)
        headers = request_headers token
        RestClient.get url, headers
      end
    end

    def self.order_acknowledgement_url(params)
      order_number = params[:order_number]
      order_submission_id = params[:order_submission_id]
      "#{@order_acknowledgement_api_url}/#{@account_number}/#{order_number}/#{order_submission_id}"
    end

    def self.order_status_url(order_number)
      "#{@order_status_api_url}/#{@account_number}?orderNumber=#{order_number}"
    end

    def self.shipment_details_url(order_number)
      "#{@order_shipment_details_api_url}/#{@account_number}?orderNumber=#{order_number}"
    end

    def self.already_in_system?(response)
      api_errors(response).any? { |error| error['ErrorCode'] == ALREADY_IN_SYSTEM }
    end

    def self.acknowledgement_errors?(response)
      api_errors(response).count.positive?
    end

    def self.api_errors(response)
      payload = JSON.parse(response.body)
      payload.dig('CreationAcknowledge', 'Order', 'OrderSubmission', 'Error') || []
    end

    def self.request_headers(token)
      {
          Authorization: "Bearer #{token}",
          Accept: 'application/json',
          'Content-Type' => 'application/json'
      }
    end

    def self.invalid_fields_error?(response)
      payload = JSON.parse(response.body)
      payload.dig('error', 'code') == INVALID_VALUES_FOR_FIELDS
    end

    private_class_method :order_acknowledgement_url,
                         :order_status_url,
                         :acknowledgement_errors?,
                         :request_headers,
                         :shipment_details_url,
                         :invalid_fields_error?
  end
end
