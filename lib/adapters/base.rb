# frozen_string_literal: true

module DHL
  module Fulfillment
    module Adapters
      # Provider-indepent structure for line items
      Item = Struct.new :id, :quantity, :sku, :title, :price, :fulfillment_service
      # Provider-indepent structure for Tax details
      Tax = Struct.new :amount, :name, :percentage

      # Base class for adapters
      class Base
        attr_reader :payload

        def initialize(json_payload = '{}')
          @payload = JSON.parse(json_payload)
        end

        # :reek:UtilityFunction
        def message_date_time
          Time.now.iso8601
        end

        def organization_id
          ''
        end

        def shipping_charge
          0
        end
      end
    end
  end
end
