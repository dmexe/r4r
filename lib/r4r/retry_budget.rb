module R4r
  # Represents a budget for retrying requests.
  #
  # A retry budget is useful for attenuating the amplifying effects
  # of many clients within a process retrying requests multiple
  # times. This acts as a form of coordination between those retries.
  class RetryBudget

    # Indicates a deposit, or credit, which will typically
    # permit future withdrawals.
    def deposit
      raise NotImplementedError
    end

    # Check whether or not there is enough balance remaining
    # to issue a retry, or make a withdrawal.
    #
    # @return [Boolean]
    #   `true`, if the retry is allowed and a withdrawal will take place.
    #   `false`, the balance should remain untouched.
    def try_withdraw
      raise NotImplementedError
    end

    # The balance or number of retries that can be made now.
    def balance
      raise NotImplementedError
    end

    # Creates a [R4r::RetryBudget] that allows for about `percent_can_retry` percent
    # of the total [R4r::RetryBudget#deposit] requests to be retried.
    #
    # @param [Fixnum] ttl_ms deposits created by [R4r::RetryBudget#deposit] expire after
    #   approximately `ttl_ms` time has passed. Must be `>= 1 second`
    #   and `<= 60 seconds`.
    # @param [Fixnum] min_retries_per_second the minimum rate of retries allowed in order to
    #   accommodate clients that have just started issuing requests as well as clients
    #   that do not issue many requests per window.
    #   Must be non-negative and if `0`, then no reserve is given.
    # @param [Float] percent_can_retry the percentage of calls to `deposit()` that can be
    #   retried. This is in addition to any retries allowed for via `minRetriesPerSec`.
    #   Must be >= 0 and <= 1000. As an example, if `0.1` is used, then for every
    #   10 calls to `deposit()`, 1 retry will be allowed. If `2.0` is used then every
    #   `deposit` allows for 2 retries.
    # @param [R4r::Clock] clock the current time for testing
    #
    # @raise [ArgumentError]
    def self.create(ttl_ms: nil, min_retries_per_second:, percent_can_retry:, clock: nil)
      ttl_ms = (ttl_ms || R4r::TokenRetryBudget::DEFAULT_TTL_MS).to_i
      min_retries_per_second = min_retries_per_second.to_i
      percent_can_retry = percent_can_retry.to_f

      unless ttl_ms >= 0 && ttl_ms <= 60 * 1000
        raise ArgumentError, "ttl_ms must be in [1.second, 60.seconds], got #{ttl_ms}"
      end
      unless min_retries_per_second >= 0
        raise ArgumentError, "min_retries_per_second cannot be nagative, got #{min_retries_per_second}"
      end
      unless percent_can_retry >= 0.0
        raise ArgumentError, "percent_can_retry cannot be negative, got #{percent_can_retry}"
      end
      unless percent_can_retry <= R4r::TokenRetryBudget::SCALE_FACTOR
        raise ArgumentError, "percent_can_retry cannot be greater then #{R4r::TokenRetryBudget::SCALE_FACTOR}, got #{percent_can_retry}"
      end

      if min_retries_per_second == 0 && percent_can_retry == 0.0
        return R4r::EmptyRetryBudget.new
      end

      deposit_amount = percent_can_retry == 0.0 ? 0 : R4r::TokenRetryBudget::SCALE_FACTOR.to_i
      withdrawal_amount = percent_can_retry == 0.0 ? 1 : (R4r::TokenRetryBudget::SCALE_FACTOR / percent_can_retry).to_i
      reserve = min_retries_per_second * (ttl_ms / 1000) * withdrawal_amount
      bucket = R4r::LeakyTokenBucket.new(ttl_ms: ttl_ms, reserve: reserve, clock: clock)
      R4r::TokenRetryBudget.new(bucket: bucket, deposit_amount: deposit_amount, withdrawal_amount: withdrawal_amount)
    end
  end

  # An [R4r::RetryBudget] that never has a balance,
  # and as such, will never allow a retry.
  class EmptyRetryBudget < RetryBudget
    def deposit ; end
    def try_withdraw ; false ; end
    def balance ; 0 ; end
  end

  # An immutable [R4r::RetryBudget] that always has a balance of `100`,
  # and as such, will always allow a retry.
  class InfiniteRetryBudget < RetryBudget
    def deposit ; end
    def try_withdraw ; true end
    def balance ; 100 end
  end

  class TokenRetryBudget < RetryBudget
    # This scaling factor allows for `percent_can_retry` > 1 without
    # having to use floating points (as the underlying mechanism
    # here is a [R4r::TokenBucket] which is not floating point based).
    SCALE_FACTOR = 1000
    DEFAULT_TTL_MS = 10 * 1000

    # Creates a new [R4r::TokenRetryBudget]
    #
    # @param [R4r::TokenBucket] bucket
    # @param [Fixnum] deposit_amount
    # @param [Fixnum] withdrawal_amount
    def initialize(bucket:, deposit_amount:, withdrawal_amount:)
      raise ArgumentError, "bucket cannot be nil" if bucket.nil?
      raise ArgumentError, "deposit_amount cannot be nil" if deposit_amount.nil?
      raise ArgumentError, "withdrawal_amount cannot be nil" if withdrawal_amount.nil?

      @bucket = bucket
      @deposit_amount = deposit_amount.to_i
      @withdrawal_amount = withdrawal_amount.to_i
    end

    def deposit
      @bucket.put(@deposit_amount)
    end

    def try_withdraw
      @bucket.try_get(@withdrawal_amount)
    end

    def balance
      @bucket.count / @withdrawal_amount
    end

    def to_s
      "R4r::TokenRetryBudget{deposit=#{@deposit_amount}, withdrawal=#{@withdrawal_amount}, balance=#{balance}}"
    end
  end
end
