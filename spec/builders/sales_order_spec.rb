# frozen_string_literal: true

require_relative '../dummy_adapter'

nmsp = DHL::EFulfillment

RSpec.describe nmsp::Builders::SalesOrder do
  let(:builder) do
    nmsp::Builders::SalesOrder.new(nmsp::Adapters::Dummy.new, 12_345)
  end

  describe '#build' do
    it 'returns a hash with billing address as expected by the DHL API' do
      hash = builder.build

      expect(hash).to be_a Hash
      address = hash.dig(:CreateSalesOrder, :Order, :OrderHeader, :BillTo)
      expect(address[:AddressLine1]).to eql '5th Street 123'
      expect(address[:City]).to eql 'San Francisco'
      expect(address[:State]).to eql 'CA'
      expect(address[:Country]).to eql 'United States'
      expect(address[:FirstName]).to eql 'Foo'
      expect(address[:LastName]).to eql 'Bar'
      expect(address[:ZipCode]).to eql '8923'
    end

    it 'returns a hash with shipping address as expected by the DHL API' do
      hash = builder.build

      expect(hash).to be_a Hash
      address = hash.dig(:CreateSalesOrder, :Order, :OrderHeader, :Shipto)
      expect(address[:AddressLine1]).to eql '5th Street 123'
      expect(address[:City]).to eql 'San Francisco'
      expect(address[:State]).to eql 'CA'
      expect(address[:Country]).to eql 'United States'
      expect(address[:FirstName]).to eql 'Foo'
      expect(address[:LastName]).to eql 'Bar'
      expect(address[:ZipCode]).to eql '8923'
    end

    it 'returns a hash with charges as expected by the DHL API' do
      hash = builder.build

      expect(hash).to be_a Hash
      hash = hash.dig(:CreateSalesOrder, :Order, :OrderHeader, :Charges)
      expect(hash[:OrderCurrency]).to eql 'USD'
      expect(hash[:OrderTotal]).to eql '100'
      expect(hash[:OrderSubTotal]).to eql '50'
      expect(hash[:TaxTotal]).to eql '25'
    end

    it 'returns a hash with order header params as expected by the DHL API' do
      hash = builder.build

      expect(hash).to be_a Hash
      header = hash.dig(:CreateSalesOrder, :Order, :OrderHeader)
      expect(header).not_to be_nil
      expect(header[:OrderDateTime]).to eql '2017-08-15T14:05:22-05:00'
      expect(header[:OrderNumber]).to eql '1234'
      expect(header.keys).to include :Charges, :BillTo, :Shipto
    end

    it 'returns a hash with a root element as expected by the DHL API' do
      hash = builder.build

      expect(hash).to be_a Hash
      hash = hash[:CreateSalesOrder]
      expect(hash[:OrderSubmissionID]).to eql '1'
      expect { Time.iso8601 hash[:MessageDateTime] }.not_to raise_error
      expect(hash.keys).to include :Order
    end

    it 'returns a hash with order details as expected by the DHL API' do
      hash = builder.build

      expect(hash).to be_a Hash
      hash = hash.dig(:CreateSalesOrder, :Order, :OrderDetails)

      hash[:OrderLine].each_with_index do |item, index|
        expect(item.keys).to include :ItemID
        expect(item[:OrderLineNumber]).to eql((index + 1).to_s)
        expect(item[:OrderedQuantity]).to eql '5'
        expect(item[:ItemID]).to eql "SKU#{index}"
        expect(item[:ItemDescription]).to eql "Product ##{index}"
        expect(item[:Price]).to eql '100'
      end
    end

    it 'returns a hash with tax details as expected by the DHL API' do
      hash = builder.build

      expect(hash).to be_a Hash
      hash = hash.dig(:CreateSalesOrder, :Order, :OrderHeader, :Charges)

      hash[:TaxDetail].each_with_index do |item, index|
        expect(item.keys).to include :TaxAmount, :TaxName, :TaxPercentage
        expect(item[:TaxAmount]).to eql((10 + index).to_s)
        expect(item[:TaxName]).to eql "tax #{index}"
        expect(item[:TaxPercentage]).to eql((10 + index).to_f.to_s)
      end
    end
  end
end
