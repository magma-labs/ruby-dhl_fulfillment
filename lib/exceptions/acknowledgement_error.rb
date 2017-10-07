# frozen_string_literal: true

module DHL
  module Fulfillment
    # Error to raise if order acknowledgement goes wrong.
    class AcknowledgementError < DHLAPIException
      def initialize(api_response = '')
        super('Acknowledgement error.', api_response)
      end
    end
  end
end
