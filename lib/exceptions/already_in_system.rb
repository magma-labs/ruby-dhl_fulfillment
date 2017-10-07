# frozen_string_literal: true

module DHL
  module Fulfillment
    # Error to raise if order is already in DHL's system
    class AlreadyInSystem < DHLAPIException
      def initialize(order_number, api_response = '')
        super("Order #{order_number} already in DHL systems.", api_response)
      end
    end
  end
end
