require 'concurrent/thread_safe/util/adder'
require 'concurrent/atomic/atomic_fixnum'

module R4r

  # A Ruby port of the finagle's WindowedAdder.
  #
  # @see https://github.com/twitter/util/blob/master/util-core/src/main/scala/com/twitter/util/WindowedAdder.scala
  # @see https://github.com/ruby-concurrency/concurrent-ruby/blob/master/lib/concurrent/thread_safe/util/adder.rb
  class WindowedAdder

    # Creates a time-windowed version of a {Concurrent::ThreadSafe::Util::Adder].
    #
    # @param [Fixnum] range_ms the range of time in millisecods to be kept in the adder.
    # @param [Fixnum] slices the number of slices that are maintained; a higher
    #   number of slices means finer granularity but also more memory
    #   consumption. Must be more than 1.
    # @param [R4r::Clock] clock the current time. for testing.
    #
    # @raise [ArgumentError] if slices is less then 1
    # @raise [ArgumentError] if range is nil
    # @raise [ArgumentError] if slices is nil
    def initialize(range_ms:, slices:, clock: nil)
      raise ArgumentError, "range_ms cannot be nil" if range_ms.nil?
      raise ArgumentError, "slices cannot be nil" if slices.nil?
      raise ArgumentError, "slices must be positive" if slices.to_i <= 1

      @window = range_ms.to_i / slices.to_i
      @slices = slices.to_i - 1
      @writer = ::Concurrent::ThreadSafe::Util::Adder.new
      @gen = 0
      @expired_gen = ::Concurrent::AtomicFixnum.new(@gen)
      @buf = Array.new(@slices) { 0 }
      @index = 0
      @now = (clock || R4r.clock)
      @old = @now.call
    end

    # Reset the state of the adder.
    def reset
      @buf.fill(0, @slices) { 0 }
      @writer.reset
      @old = @now.call
    end

    # Increment the adder by 1
    def incr
      add(1)
    end

    # Increment the adder by `x`
    def add(x)
      expired if (@now.call - @old) >= @window

      @writer.add(x)
    end

    # Retrieve the current sum of the adder
    #
    # @return [Fixnum]
    def sum
      expired if (@now.call - @old) >= @window

      value = @writer.sum
      i = 0
      while i < @slices
        value += @buf[i]
        i += 1
      end

      value
    end

    private

    def expired
      return unless @expired_gen.compare_and_set(@gen, @gen + 1)

      # At the time of add, we were likely up to date,
      # so we credit it to the current slice.
      @buf[@index] = @writer.sum
      @writer.reset
      @index = (@index + 1) % @slices

      # If it turns out we've skipped a number of
      # slices, we adjust for that here.
      nskip = [((@now.call - @old) / @window) - 1, @slices].min

      if nskip > 0
        r = [nskip, @slices - @index].min
        @buf.fill(@index, r) { 0 }
        @buf.fill(0, nskip - r) { 0 }
        @index = (@index + nskip) % @slices
      end

      @old = @now.call
      @gen += 1
    end

  end
end
