# frozen_string_literal: true

module DHL
  # :reek:Attribute
  # :reek:FeatureEnvy
  # Connector for the DHL Fulfillment API (https://api-qa.dhlecommerce.com/fulfillment)
  module Fulfillment
    API_TIMEOUT = 10
    ALREADY_IN_SYSTEM = 'YFC0001'
    INVALID_VALUES_FOR_FIELDS = '919'

    class << self
      attr_reader :urls
      attr_accessor :client_id, :client_secret, :account_number
      attr_writer :token_store

      def configure
        yield self
      end

      def urls=(urls_class)
        @urls = if urls_class.is_a?(Symbol) || urls_class.is_a?(String)
                  "DHL::Fulfillment::Urls::#{urls_class.to_s.camelize}".constantize.new
                else
                  urls_class
                end
      end

      def create_sales_order(options)
        call_api method: :post, url: @urls.order_create, body: options.to_json do |response|
          raise InvalidValuesFoundForFields if invalid_fields_error?(response)
          raise APIException, "Can't create sales order", response.body unless response.code == 202
          true
        end
      end

      def sales_order_acknowledgement(order_number, submission_ud)
        url = order_acknowledgement_url(order_number, submission_ud)
        call_api method: :get, url: url do |res|
          body = res.body
          raise AlreadyInSystem, order_number, body if already_in_system?(res)
          raise AcknowledgementError, body if acknowledgement_errors?(res)
          raise APIException, "Can't acknowledge sales order", body unless res.code == 200
          true
        end
      end

      def sales_order_status(order_number)
        call_api method: :get, url: order_status_url(order_number) do |res|
          raise APIException, "Can't check sales order status", res.body unless res.code == 200
          true
        end
      end

      def shipment_details(order_number)
        call_api method: :get, url: shipment_details_url(order_number) do |res|
          raise APIException, "Can't access shipment details", res.body unless res.code == 200
          true
        end
      end

      def token_store
        @token_store ||= TokenStore.new(@client_id, @client_secret, @urls)
      end

      protected

      def call_api(method:, url:, body: nil)
        ExceptionUtils.handle_error_rethrow do
          response = RestClient::Request.execute method: method,
                                                 url: url,
                                                 body: body,
                                                 headers: request_headers,
                                                 timeout: API_TIMEOUT
          yield(response) if block_given?
        end
      end

      def order_acknowledgement_url(order_number, submission_id)
        "#{@urls.order_acknowledgement}/#{@account_number}/#{order_number}/#{submission_id}"
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

      def request_headers
        {
            'Authorization' => "Bearer #{token_store.api_token}",
            'Accept'        => 'application/json',
            'Content-Type'  => 'application/json'
        }
      end

      def invalid_fields_error?(response)
        payload = JSON.parse(response.body)
        payload.dig('error', 'code') == INVALID_VALUES_FOR_FIELDS
      end
    end
  end
end
