# frozen_string_literal: true

module DHL
  module Fulfillment
    # Error to raise if order acknowledgement goes wrong.
    class AcknowledgementError < APIException
      def initialize(api_response = '')
        super('Acknowledgement error.', api_response)
      end
    end
  end
end
