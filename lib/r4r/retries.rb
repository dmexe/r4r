module R4r

  # Decorator that warp a block and call it within retries.
  class Retries

    # Creates a new [R4r::RetriesDecorator].
    #
    # @param [Fixnum] min_retries_per_seconds
    # @param [Float] percent_can_retry
    # @param [Array[Float]] backoff
    # @param [Fixnum] num_retries
    # @param [Lambda] policy
    # @param [R4r::RetryBudget] budget
    def initialize(
      min_retries_per_second: nil,
      percent_can_retry: nil,
      backoff: nil,
      num_retries: nil,
      policy: nil,
      budget: nil
    )
      @policy = policy

      if num_retries != nil
        @backoff = Array.new(num_retries) { Array(backoff).first.to_f }
      else
        @backoff = Array.new(backoff).map { |i| i.to_f }
      end

      if budget != nil
        @budget = budget
      else
        @budget = R4r::RetryBudget.create(
          min_retries_per_second: min_retries_per_second,
          percent_can_retry: percent_can_retry
        )
      end
    end

    # Decorates a given block within retries.
    def decorate(&block)
      ->() {
        call { yield }
      }
    end

    # Calls given block within retries.
    def call(&block)
      return unless block_given?

      num_retry = 0
      @backoff.size
      @budget.deposit

      while num_retry < @backoff.size
        begin
          return yield(num_retry)
        rescue => err
          can_rescue = @policy ? @policy.call(err, num_retry) : true
          raise err unless can_rescue
          raise err unless @budget.try_withdraw
        end

        sleep @backoff[num_retry]
        num_retry += 1
      end
    end

  end
end
