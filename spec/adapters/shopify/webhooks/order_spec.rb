# frozen_string_literal: true

require 'spec_helper'

nmsp = DHL::Fulfillment::Adapters::Shopify::Webhooks

RSpec.describe nmsp::Order do
  let(:payload_file) { "#{File.dirname(__FILE__)}/payload.json" }
  let(:payload) { File.read(payload_file) }
  let(:adapter) { nmsp::Order.new(payload) }

  describe '#order_number' do
    it 'returns the correct order number' do
      expect(adapter.order_number).to eql 1234
    end
  end

  describe '#shipping_charge' do
    it 'returns the correct shipping charge' do
      expect(adapter.shipping_charge).to eql 11.50
    end
  end

  describe '#tax_details' do
    it 'returns the correct tax details' do
      tax_array = adapter.tax_details
      expect(tax_array[0].amount).to eql '1.45'
      expect(tax_array[0].name).to eql 'CA State Tax'
      expect(tax_array[0].percentage).to eql 7.25
      expect(tax_array[1].amount).to eql '0.40'
      expect(tax_array[1].name).to eql 'Los Angeles County Tax is veeeeeeeeeery '
      expect(tax_array[1].name.length).to eql 40
      expect(tax_array[1].percentage).to eql 2.0
    end
  end

  context 'when a payload doesnt include a billing_address object' do
    let(:payload) do
      payload = JSON.parse File.read(payload_file)
      payload.delete('billing_address')
      payload.to_json
    end

    let(:shipping_address) { JSON.parse(payload)['shipping_address'] }

    describe '#billing_address' do
      it 'uses shipping address information' do
        expect(adapter.billing_address).to eql shipping_address['address1']
      end
    end

    describe '#billing_city' do
      it 'uses shipping address information' do
        expect(adapter.billing_city).to eql shipping_address['city']
      end
    end

    describe '#billing_country' do
      it 'uses shipping address information' do
        expect(adapter.billing_country).to eql shipping_address['country_code']
      end
    end

    describe '#billing_first_name' do
      it 'uses shipping address information' do
        expect(adapter.billing_first_name).to eql shipping_address['first_name']
      end
    end

    describe '#billing_last_name' do
      it 'uses shipping address information' do
        expect(adapter.billing_last_name).to eql shipping_address['last_name']
      end
    end

    describe '#billing_zip' do
      it 'uses shipping address information' do
        expect(adapter.billing_zip).to eql shipping_address['zip']
      end
    end

    describe '#billing_state' do
      it 'uses shipping address information' do
        expect(adapter.billing_state).to eql shipping_address['province_code']
      end
    end
  end

  describe '#billing_state' do
    context 'when payload has billing_address.province_code as nil' do
      let(:payload) do
        payload = JSON.parse File.read(payload_file)
        payload['billing_address']['province'] = 'Maryland ' # Note the blank space
        payload['billing_address']['province_code'] = nil
        payload.to_json
      end

      it 'trims the state name and finds its code using a mappings file' do
        expect(adapter.billing_state).to eql 'MD'
      end
    end
  end

  describe '#shipping_state' do
    context 'when payload has shipping_address.province_code as nil' do
      let(:payload) do
        payload = JSON.parse File.read(payload_file)
        payload['shipping_address']['province'] = 'Maryland ' # Note the blank space
        payload['shipping_address']['province_code'] = nil
        payload.to_json
      end

      it 'trims the state name and finds its code using a mappings file' do
        expect(adapter.shipping_state).to eql 'MD'
      end
    end
  end
end
