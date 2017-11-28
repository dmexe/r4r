module R4r

  # Decorator that warp a block and call it within retries.
  class RetriesDecorator

    # Creates a new [R4r::RetriesDecorator].
    #
    # @param [Fixnum] min_retries_per_seconds
    # @param [Float] percent_can_retry
    # @param [Array[Float]] backoff
    # @param [Fixnum] num_retries
    # @param [Lambda] policy
    # @param [R4r::RetryBudget] budget
    def initialize(
      min_retries_per_seconds: nil,
      percent_can_retry: nil,
      backoff: nil,
      num_retries: nil,
      policy: nil,
      budget: nil
    )
      @policy = policy
      @backoff = num_retries.to_i > 0 ?
        Array.new(num_retries.to_i) { 0 } :
        Array(backoff).map { |i| i.to_f }
      @budget = budget ?
        budget :
        R4r::RetryBudget.create(min_retries_per_seconds: min_retries_per_seconds, percent_can_retry: percent_can_retry)
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
          yield num_retry
        rescue Exception => err
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
