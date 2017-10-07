# frozen_string_literal: true

# Helper module for retrying something several times
# Example: attempt(3).times { do_something }
module Retry
  def attempt(max_attempts)
    @retry_max = max_attempts
    @retry_count = 0
    self
  end

  def times(&block)
    @retry_block = block
    block.yield
  end

  def next_try!
    raise OutOfRetryAttempts if @retry_count >= @retry_max
    @retry_count + +
    @retry_block.yield
  end

  # Exception to raise when running out of retry attempts
  class OutOfRetryAttempts < ::RuntimeError; end
end
