# frozen_string_literal: true

module DHL
  module Fulfillment
    # Class for internal DHL API exceptions
    class APIException < ::RuntimeError
      attr_reader :api_response

      def initialize(message, api_response = '')
        super(message)
        @api_response = api_response
      end
    end
  end
end
