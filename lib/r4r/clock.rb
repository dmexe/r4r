module R4r
  # A system clock
  class Clock
    # Returns current system time in milliseconds
    def call
      raise NotImplementedError
    end
  end

  # A frozen clock for testing
  class FrozenClock < Clock
    # Creates a new instance of frozen clock.
    #
    # @param [R4r::Clock] parent an initial time clock
    def initialize(parent: nil)
      @time = (parent || R4r.clock).call
    end

    # @see R4r::Clock#call
    def call
      @time
    end

    # Increase clock time by given seconds.
    #
    # @param [Fixnum] seconds a number of seconds to increase time
    def advance(seconds:)
      @time += (seconds.to_i * 1_000)
    end
  end

  @@clock = R4r::SystemClockExt.new

  # Default {R4r::Clock} instance.
  def self.clock
    @@clock
  end
end
