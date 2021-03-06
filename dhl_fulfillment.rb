# frozen_string_literal: true

require 'json'

require 'active_support/core_ext/string'
require 'active_support/core_ext/object/blank'

require_relative 'lib/adapters/base'
require_relative 'lib/adapters/shopify/webhooks/order'
require_relative 'lib/builders/sales_order'
require_relative 'lib/exceptions/dhl_api_exception'
require_relative 'lib/exceptions/acknowledgement_error'
require_relative 'lib/exceptions/invalid_values_found_for_fields'
require_relative 'lib/urls/sandbox'
require_relative 'lib/urls/production'
require_relative 'lib/dhl_fulfillment'
