# frozen_string_literal: true

module DHL
  module EFulfillment
    module Urls
      # Urls for accessing the sandbox API. Useful for staging environments.
      class Sandbox
        def token_get
          'https://api-qa.dhlecommerce.com/efulfillment/v1/auth/accesstoken'
        end

        def order_create
          'https://api-qa.dhlecommerce.com/efulfillment/v1/order'
        end

        def order_acknowledgement
          'https://api-qa.dhlecommerce.com/efulfillment/v1/order/acknowledgement'
        end

        def order_status
          'https://api-qa.dhlecommerce.com/efulfillment/v1/order/status'
        end

        def shipment_details
          'https://api-qa.dhlecommerce.com/efulfillment/v1/shipment/details'
        end
      end
    end
  end
end
