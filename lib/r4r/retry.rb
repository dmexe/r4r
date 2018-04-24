module R4r
  # Decorator that wrap blocks and call it within retries.
  #
  # @attr [Array[Float]] backoff
  # @attr [R4r::RetryBudget] budget
  #
  # @example constant backoff, it will never pause between retries and will try 3 times.
  #   retry = R4r::Retry.constant_backoff(num_retries: 3)
  #   retry.call { get_http_request }
  #
  # @example exponential backoff, it will pause between invocations using given backoff invtervals and will try 4 times
  #   retry = R4r::Retry.backoff(backoff: [0.1, 0.3, 1, 5])
  #   retry.call { get_http_request }
  #
  class Retry

    attr_reader :backoff
    attr_reader :budget

    # Creates a new retries dectorator.
    #
    # @param [Array[Float]] backoff an array with backoff intervals (in seconds)
    # @param [R4r::RetryPolicy] policy a policy used for error filtiring
    # @param [R4r::RetryBudget] budget a retry budget
    #
    # @raise [ArgumentError] when backoff is empty
    # @raise [ArgumentError] when backoff has negative values
    def initialize(backoff:, policy: nil, budget: nil)
      @policy = (policy || R4r::RetryPolicy.always)
      @backoff = Array.new(backoff).map { |i| i.to_f }
      @budget = budget != nil ? budget : R4r::RetryBudget.create

      raise ArgumentError, "backoff cannot be empty" if @backoff.empty?
      raise ArgumentError, "backoff values cannot be negative" unless @backoff.all? {|i| i.to_f >= 0.0 }
    end

    # Decorates a given block within retries.
    #
    # @return [Proc]
    def decorate(&block)
      ->() { call { yield } }
    end

    # Calls given block within retries.
    #
    # @raise [NonRetriableError]
    def call(&block)
      return unless block_given?

      num_retry = 0
      @budget.deposit

      while num_retry <= @backoff.size

        begin
          return yield(num_retry)
        rescue => err
          raise err if err.is_a?(NonRetriableError)

          if (num_retry + 1 > @backoff.size)
            raise NonRetriableError.new(
              message: "Retry limit [#{@backoff.size}] reached: #{err}",
              kind: NonRetriableError::KIND_LIMIT_REACHED,
              cause: err
            )
          end

          unless @policy.call(error: err, num_retry: num_retry)
            raise NonRetriableError.new(
              message: "An error was rejected by policy: #{err}",
              kind: NonRetriableError::KIND_REJECTED_BY_POLICY,
              cause: err
            )
          end

          unless @budget.try_withdraw
            raise NonRetriableError.new(
              message: "Budget was exhausted: #{err}",
              kind: NonRetriableError::KIND_BUDGET_EXHAUSTED,
              cause: err
            )
          end
        end

        sleep @backoff[num_retry]
        num_retry += 1
      end
    end

    # Creates a {R4r::Retry} with fixed backoff rates.
    #
    # @param [R4r::RetryPolicy] policy a policy used for error filtiring
    # @param [R4r::RetryBudget] budget a retry budget
    # @return [R4r::Retry]
    #
    # @raise [ArgumentError] when num_retries is negative
    # @raise [ArgumentError] when backoff is negative
    #
    # @example without sleep between invocations
    #   R4r::Retry.constant_backoff(num_retries:3)
    #
    # @example with sleep 1s between invocations
    #   R4r::Retry.constant_backoff(num_retries: 3, backoff: 1)
    def self.constant_backoff(num_retries:, backoff: 0.0, policy: nil, budget: nil)
      raise ArgumentError, "num_retries cannot be negative" unless num_retries.to_i >= 0
      raise ArgumentError, "backoff cannot be negative" unless backoff.to_f >= 0.0

      backoff = Array.new(num_retries.to_i) { backoff.to_f }
      R4r::Retry.new(backoff: backoff, policy: policy, budget: budget)
    end

    # Creates a {R4r::Retry} with backoff intervals.
    #
    # @param [Array[Float]] backoff a list of sleep intervals (in seconds)
    # @param [R4r::RetryPolicy] policy a policy used for error filtiring
    # @param [R4r::RetryBudget] budget a retry budget
    # @return [R4r::Retry]
    #
    # @raise [ArgumentError] when backoff is nil
    # @raise [ArgumentError] when backoff isn't array
    # @raise [ArgumentError] when backoff has negative values
    #
    # @example exponential backoff between invocations
    #   R4r::Retry.backoff(backoff: [0.1, 0.5, 1, 3])
    def self.backoff(backoff:, policy: nil, budget: nil)
      raise ArgumentError, "backoff cannot be nil" if backoff.nil?
      raise ArgumentError, "backoff must be an array" unless backoff.is_a?(Array)
      raise ArgumentError, "backoff values cannot be negative" unless backoff.all? {|i| i.to_f >= 0.0 }

      R4r::Retry.new(backoff: backoff, policy: policy, budget: budget)
    end

  end
end
