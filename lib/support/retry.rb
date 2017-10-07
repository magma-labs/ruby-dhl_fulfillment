# frozen_string_literal: true

# Helper module for retrying something several times
#
# Usage:
#   attempt(3).times do
#     success = do_something
#     next_try! if not success
#   end
#
module Retry
  protected

  def attempt(max_attempts)
    @retry_max = max_attempts
    self
  end

  def times
    @retry_max.times do
      begin
        return yield if block_given?
      rescue NextTry
        next
      end
    end
    raise OutOfAttempts
  end

  def next_try!
    raise NextTry
  end

  # Exception to raise to trigger a retry
  class NextTry < RuntimeError; end
  # Exception to raise when running out of retry attempts
  class OutOfAttempts < RuntimeError; end
end
