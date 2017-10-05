# frozen_string_literal: true

require 'json'

module DHL
  module EFulfillment
    module Adapters
      module Shopify
        module Webhooks
          # :reek:TooManyMethods
          # :reek:NilCheck
          # :reek:FeatureEnvy
          # rubocop:disable Metrics/ClassLength
          # Adapter for the shopify order
          class Order < ::DHL::EFulfillment::Adapters::Base
            DEFAULT_FIRST_NAME = 'Customer'
            STATE_CODES_FILE = "#{File.dirname __FILE__}/../../../../us_state_codes.json"
            STATE_CODES = JSON.parse(File.read(STATE_CODES_FILE)).freeze

            def order_id
              payload['id']
            end

            def order_number
              payload['order_number']
            end

            def created_at
              payload['created_at']
            end

            def currency
              payload['currency']
            end

            def total
              payload['total_price']
            end

            def subtotal
              payload['subtotal_price']
            end

            def total_tax
              payload['total_tax']
            end

            def billing_address
              payload.dig('billing_address', 'address1') || shipping_address
            end

            def billing_city
              payload.dig('billing_address', 'city') || shipping_city
            end

            def billing_country
              payload.dig('billing_address', 'country_code') || shipping_country
            end

            def billing_first_name
              value = payload.dig('billing_address', 'first_name')
              value.present? ? value : shipping_first_name
            end

            def billing_last_name
              payload.dig('billing_address', 'last_name') || shipping_last_name
            end

            def billing_zip
              payload.dig('billing_address', 'zip') || shipping_zip
            end

            def billing_state
              address = payload['billing_address']
              if address.present?
                value = address['province_code']
                value.blank? ? find_state_code_for(:billing) : value
              else
                shipping_state
              end
            end

            def shipping_address
              payload.dig('shipping_address', 'address1')
            end

            def shipping_city
              payload.dig('shipping_address', 'city')
            end

            def shipping_country
              payload.dig('shipping_address', 'country_code')
            end

            def shipping_first_name
              value = payload.dig('shipping_address', 'first_name')
              value.present? ? value : DEFAULT_FIRST_NAME
            end

            def shipping_last_name
              payload.dig('shipping_address', 'last_name')
            end

            def shipping_zip
              payload.dig('shipping_address', 'zip')
            end

            def shipping_state
              value = payload.dig('shipping_address', 'province_code')
              value.blank? ? find_state_code_for(:shipping) : value
            end

            def shipping_charge
              payload['shipping_lines'].reduce(0) do |sum, shipping_line|
                sum + shipping_line['price'].to_f
              end
            end

            # :reek:FeatureEnvy
            def tax_details
              payload['tax_lines'].map do |tax|
                Tax.new(tax['price'],
                        tax_title(tax['title']),
                        (tax['rate'].to_f * 100).ceil(2))
              end
            end

            # :reek:FeatureEnvy
            def items
              payload['line_items'].map do |line_item|
                Item.new line_item['id'],
                         line_item['quantity'],
                         line_item['sku'],
                         line_item['title'],
                         line_item['price'],
                         line_item['fulfillment_service']
              end
            end

            def shipping_phone
              payload.dig('shipping_address', 'phone')
            end

            def billing_phone
              payload.dig('billing_address', 'phone')
            end

            private

            # :reek:UtilityFunction
            def tax_title(title)
              title.length > 40 ? title[0...40] : title
            end

            def find_state_code_for(address_type)
              state_name = payload.dig("#{address_type}_address", 'province').to_s
              STATE_CODES.key(state_name.strip.downcase) || ''
            end
          end
        end
      end
    end
  end
end
