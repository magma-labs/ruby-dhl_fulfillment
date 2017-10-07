# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Retry do
  let(:test_object) { spy }

  before do
    extend Retry
  end

  context 'when the running block calls next_try!' do
    it 'keeps retrying until it runs out of retry attempts' do
      begin
        attempt(5).times do
          test_object.do_something
          next_try!
        end
      rescue Retry::OutOfAttempts
        test_object.do_other_thing
      end

      expect(test_object).to have_received(:do_something).exactly(5).times
    end

    context 'when it runs out of retry attempts' do
      it 'raises an exception' do
        block = proc do
          attempt(5).times do
            test_object.do_something
            next_try!
          end
        end

        expect(&block).to raise_error Retry::OutOfAttempts
      end
    end
  end

  context 'when the running block doesnt call next_try!' do
    before do
      allow(test_object).to receive(:do_something) { 'value' }
    end

    it 'stops executing the block' do
      attempt(5).times { test_object.do_something }
      expect(test_object).to have_received(:do_something).once
    end

    it 'returns the block result' do
      result = attempt(5).times { test_object.do_something }
      expect(result).to eql 'value'
    end
  end
end
