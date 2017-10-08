# frozen_string_literal: true

module DHL
  module Fulfillment
    # Class to raise when the API returns an unauthorized response
    class Unauthorized < APIException; end
  end
end
