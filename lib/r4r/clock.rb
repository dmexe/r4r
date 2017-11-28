module R4r
  # A system clock
  class Clock
    # Returns current system time in milliseconds
    def call
      raise NotImplementedError
    end
  end

  # A ruby time clock
  class DefaultClock < Clock
    def call
      (Time.now.to_f * 1_000).to_i
    end
  end

  # A frozen clock for testing
  class FrozenClock < Clock
    def initialize(parent: nil)
      @time = (parent || R4r.clock).call
    end

    def call
      @time
    end

    def advance(seconds:)
      @time += (seconds.to_i * 1_000)
    end
  end

  @@clock = DefaultClock.new

  def self.clock
    @@clock
  end
end
