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
  end
end
