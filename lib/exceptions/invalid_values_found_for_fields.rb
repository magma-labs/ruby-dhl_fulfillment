# frozen_string_literal: true

module DHL
  module EFulfillment
    # This error is meant to be thrown when the DHL API responds with something like this:
    # {
    #   "session": "Id-0210c6598835bf1aa7775682",
    #   "error": {
    #     "code": "919",
    #     "description": "Invalid value(s) found for field(s) : Order Number, Order Submission ID"
    #   }
    # }
    class InvalidValuesFoundForFields < DHLAPIException
      def initialize(api_response = '')
        super JSON.parse(api_response).dig('error', 'description'), api_response
      rescue JSON::ParserError
        super 'Invalid values for some field(s). Check API response for details.', api_response
      end
    end
  end
end
