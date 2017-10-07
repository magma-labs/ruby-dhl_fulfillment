# frozen_string_literal: true

module DHL
  module Fulfillment
    module Urls
      # Urls for accessing the production API. This is the real thing.
      class Production
        def token_get
          'https://api.dhlecommerce.com/Fulfillment/v1/auth/accesstoken'
        end

        def order_create
          'https://api.dhlecommerce.com/Fulfillment/v1/order'
        end

        def order_acknowledegment
          'https://api.dhlecommerce.com/Fulfillment/v1/order/acknowledgement'
        end

        def order_status
          'https://api.dhlecommerce.com/Fulfillment/v1/order/status'
        end

        def shipment_details
          'https://api.dhlecommerce.com/Fulfillment/v1/shipment/details'
        end
      end
    end
  end
end
