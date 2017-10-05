# frozen_string_literal: true

module DHL
  module EFulfillment
    # Class for internal DHL API exceptions
    class DHLAPIException < ::RuntimeError
      attr_reader :api_response

      def initialize(message, api_response = '')
        super(message)
        @api_response = api_response
      end
    end
  end
end
