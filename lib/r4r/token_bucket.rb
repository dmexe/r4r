module R4r
  # A token bucket is used to control the relative rates of two
  # processes: one fills the bucket, another empties it.
  #
  # A Ruby port of the finagle's TokenBucket.
  #
  # @see https://github.com/twitter/util/blob/master/util-core/src/main/scala/com/twitter/util/TokenBucket.scala
  class TokenBucket
    # Put `n` tokens into the bucket.
    #
    # @param [Fixnum] n the number of tokens to remove from the bucket.
    #   Must be >= 0.
    def put(n)
      raise NotImplementedError
    end

    # Try to get `n` tokens out of the bucket.
    #
    # @param [Fixnum] n the number of tokens to remove from the bucket.
    #   Must be >= 0.
    # @return [Boolean] true if successful
    def try_get(n)
      raise NotImplementedError
    end

    # The number of tokens currently in the bucket.
    def count
      raise NotImplementedError
    end
  end

  # A token bucket that doesn't exceed a given bound.
  #
  # This is threadsafe, and does not require further synchronization.
  # The token bucket starts empty.
  class BoundedTokenBucket < TokenBucket

    # Creates a new {R4r::BoundedTokenBucket}.
    #
    # @param [Fixnum] limit the upper bound on the number of tokens in the bucket.
    # @raise [ArgumentError] if limit isn't positive
    def initialize(limit:)
      raise ArgumentError, "limit must be positive, got #{limit}" if limit.to_i <= 0

      @limit = limit.to_i
      @counter = 0
    end

    # Put `n` tokens into the bucket.
    #
    # If putting in `n` tokens would overflow `limit` tokens, instead sets the
    # number of tokens to be `limit`.
    #
    # @raise [ArgumentError] is n isn't positive
    def put(n)
      n = n.to_i
      raise ArgumentError, "number of tokens must be positive" if n <= 0

      @counter = [@counter + n, @limit].min
    end

    # @see R4r::TokenBucket#try_get
    def try_get(n)
      n = n.to_i
      raise ArgumentError, "number of tokens must be positive" if n <= 0

      ok = @counter >= n

      if ok
        @counter -= n
      end

      ok
    end

    # @see R4r::TokenBucket#count
    def count
      @counter
    end
  end

  # A leaky bucket expires tokens after approximately `ttl` time.
  # Thus, a bucket left alone will empty itself.
  class LeakyTokenBucket < TokenBucket

    # Creates a new [R4r::LeakyTokenBucket]
    #
    # @param [Fixnum] ttl_ms the (approximate) time in milliseconds after which a token will
    #   expire.
    # @param [Fixnum] reserve the number of reserve tokens over the TTL
    #   period. That is, every `ttl` has `reserve` tokens in addition to
    #   the ones added to the bucket.
    # @param [R4r::Clock] clock the current time
    def initialize(ttl_ms:, reserve:, clock: nil)
      @ttl_ms = ttl_ms.to_i
      @reserve = reserve.to_i
      @clock = (clock || R4r.clock)
      @window = R4r::WindowedAdder.new(range_ms: ttl_ms, slices: 10, clock: @clock)
    end

    # @see R4r::TokenBucket#put
    def put(n)
      n = n.to_i
      raise ArgumentError, "n cannot be nagative" unless n >= 0

      @window.add(n)
    end

    # @see R4r::TokenBucket#try_get
    def try_get(n)
      n = n.to_i
      raise ArgumentError, "n cannot be nagative" unless n >= 0

      ok = count >= n
      if ok
        @window.add(n * -1)
      end

      ok
    end

    # @see R4r::TokenBucket#count
    def count
      @window.sum + @reserve
    end

  end
end
