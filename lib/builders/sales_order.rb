# frozen_string_literal: true

module DHL
  module Fulfillment
    module Builders
      # builds the sales order payload
      # rubocop:disable Metrics/ClassLength
      class SalesOrder
        MAX_STRING_LENGTH = 35

        attr_reader :adapter, :account_number

        def initialize(adapter, account_number = nil)
          @adapter = adapter
          @payload = nil
          @account_number = account_number || DHL::Fulfillment.account_number
        end

        def build
          @payload = { CreateSalesOrder: create_sales_order }
        end

        private

        def create_sales_order
          {
              MessageDateTime: @adapter.message_date_time,
              OrderSubmissionID: @adapter.order_submission_id.to_s,
              AccountNumber: @account_number.to_s,
              OrgID: @adapter.organization_id.to_s,
              Order: order
          }
        end

        def order
          {
              OrderHeader: order_header,
              OrderDetails: order_details
          }
        end

        def order_header
          {
              OrderDateTime: @adapter.created_at,
              OrderNumber: @adapter.order_number.to_s,
              ShippingServiceID: @adapter.shipping_service_id.to_s,
              Charges: charges,
              BillTo: bill_to,
              Shipto: ship_to
          }
        end

        def charges
          {
              OrderCurrency: @adapter.currency.upcase,
              OrderTotal: @adapter.total.to_s,
              OrderSubTotal: @adapter.subtotal.to_s,
              TaxTotal: @adapter.total_tax.to_s,
              TotalShippingCharge: @adapter.shipping_charge.to_s,
              TaxDetail: tax_detail
          }
        end

        def tax_detail
          @adapter.tax_details.map do |tax|
            tax_item tax
          end
        end

        # :reek:UtilityFunction
        def tax_item(tax)
          {
              TaxAmount: tax.amount.to_s,
              TaxName: tax.name,
              TaxPercentage: tax.percentage.to_s
          }
        end

        def bill_to
          address_for('billing').merge City: @adapter.billing_city.truncate(MAX_STRING_LENGTH),
                                       State: @adapter.billing_state,
                                       Country: @adapter.billing_country,
                                       FirstName: @adapter.billing_first_name,
                                       LastName: @adapter.billing_last_name,
                                       PhoneNumber: @adapter.billing_phone,
                                       ZipCode: @adapter.billing_zip
        end

        # :reek:FeatureEnvy
        def address_for(type)
          first = @adapter.send("#{type}_address") || ''
          second = @adapter.send("#{type}_address_2") || ''
          if first.length <= MAX_STRING_LENGTH
            { AddressLine1: first, AddressLine2: second }
          else
            splitted_part = first[MAX_STRING_LENGTH..-1]
            second = second.present? ? "#{splitted_part} #{second}" : splitted_part
            { AddressLine1: first[0...MAX_STRING_LENGTH], AddressLine2: second }
          end
        end

        def ship_to
          address_for('shipping').merge City: @adapter.shipping_city,
                                        State: @adapter.shipping_state,
                                        Country: @adapter.shipping_country,
                                        FirstName: @adapter.shipping_first_name,
                                        LastName: @adapter.shipping_last_name,
                                        PhoneNumber: @adapter.shipping_phone,
                                        ZipCode: @adapter.shipping_zip
        end

        def order_details
          {
              OrderLine: @adapter.items.each_with_index.map do |item, index|
                order_details_for_item(item, index)
              end
          }
        end

        # :reek:FeatureEnvy
        # :reek:UtilityFunction
        def order_details_for_item(item, index)
          {
              OrderLineNumber: (index + 1).to_s,
              OrderedQuantity: item.quantity.to_s,
              ItemID: item.sku,
              ItemDescription: item.title,
              Price: item.price.to_s
          }
        end
      end
    end
  end
end
