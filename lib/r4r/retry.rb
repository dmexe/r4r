module R4r

  class NonRetriableError < RuntimeError
    attr_reader :cause

    def initialize(message:, cause:)
      super(message)
      @cause = cause
    end
  end

  # Decorator that wrap blocks and call it within retries.
  class Retry

    attr_reader :backoff
    attr_reader :budget

    # Creates a new retries dectorator.
    #
    # @param [Array[Float]] backoff an array with backoff timeouts in seconds
    # @param [R4r::RetryPolicy] policy
    # @param [R4r::RetryBudget] budget
    #
    # @raise [ArgumentError] when backoff is empty
    # @raise [ArgumentError] when backoff was a negative values
    def initialize(backoff: nil, policy: nil, budget: nil)
      @policy = (policy || R4r::RetryPolicy.always)
      @backoff = Array.new(backoff).map { |i| i.to_f }
      @budget = budget != nil ? budget : R4r::RetryBudget.create

      raise ArgumentError, "backoff cannot be empty" if @backoff.empty?
      raise ArgumentError, "backoff values cannot be negative" unless @backoff.all? {|i| i.to_f >= 0.0 }
    end

    # Decorates a given block within retries.
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

      while num_retry < @backoff.size

        begin
          return yield(num_retry)
        rescue => err
          raise err if err.is_a?(NonRetriableError)

          if (num_retry + 1 == @backoff.size)
            raise NonRetriableError.new(message: "Retry limit [#{@backoff.size}] reached: #{err}", cause: err)
          end

          unless @policy.call(error: err, num_retry: num_retry)
            raise NonRetriableError.new(message: "An error was rejected by policy: #{err}", cause: err)
          end

          unless @budget.try_withdraw
            raise NonRetriableError.new(message: "Budget was exhausted: #{err}", cause: err)
          end
        end

        sleep @backoff[num_retry]
        num_retry += 1
      end
    end

    def self.constant_backoff(num_retries:, backoff: 0.0, policy: nil, budget: nil)
      raise ArgumentError, "num_retries cannot be negative" unless num_retries.to_i >= 0
      raise ArgumentError, "backoff cannot be negative" unless backoff.to_f >= 0.0

      backoff = Array.new(num_retries.to_i) { backoff.to_f }
      R4r::Retry.new(backoff: backoff, policy: policy, budget: budget)
    end

    def self.backoff(backoff:, policy: nil, budget: nil)
      raise ArgumentError, "backoff cannot be nil" if backoff.nil?
      raise ArgumentError, "backoff must be an array" unless backoff.is_a?(Array)
      raise ArgumentError, "backoff values cannot be negative" unless backoff.all? {|i| i.to_f >= 0.0 }

      R4r::Retry.new(backoff: backoff, policy: policy, budget: budget)
    end

  end
end
