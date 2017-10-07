# frozen_string_literal: true

module DHL
  module Fulfillment
    module Adapters
      # Dummy adapter useful for testing
      # :reek:TooManyMethods
      class Dummy < Base
        def message_date_time
          '2017-08-15T14:05:22-05:00'
        end

        def order_id
          '1'
        end

        def order_number
          1234
        end

        def order_submission_id
          1
        end

        def organization_id
          '2'
        end

        def created_at
          '2017-08-15T14:05:22-05:00'
        end

        def shipping_service_id
          '3'
        end

        def currency
          'USD'
        end

        def total
          100
        end

        def subtotal
          50
        end

        def total_tax
          25
        end

        def shipping_charge
          30
        end

        def billing_address
          '5th Street 123'
        end

        def billing_city
          'San Francisco'
        end

        def billing_country
          'United States'
        end

        def billing_first_name
          'Foo'
        end

        def billing_last_name
          'Bar'
        end

        def billing_zip
          '8923'
        end

        def billing_state
          'CA'
        end

        def billing_phone
          '1234567890'
        end

        def shipping_address
          '5th Street 123'
        end

        def shipping_city
          'San Francisco'
        end

        def shipping_country
          'United States'
        end

        def shipping_first_name
          'Foo'
        end

        def shipping_last_name
          'Bar'
        end

        def shipping_zip
          '8923'
        end

        def shipping_state
          'CA'
        end

        def shipping_phone
          '1234567890'
        end

        # :reek:UtilityFunction
        def tax_details
          [1..3].each_with_index.map do |_tax, index|
            Tax.new (10 + index).to_s, "tax #{index}", (10 + index).to_f
          end
        end

        # :reek:UtilityFunction
        def items
          [1..3].each_with_index.map do |_line_item, index|
            Item.new index, 5, "SKU#{index}", "Product ##{index}", 100
          end
        end
      end
    end
  end
end
