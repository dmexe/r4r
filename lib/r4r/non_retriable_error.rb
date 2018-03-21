module R4r
  # An error raises when retry was failed.
  #
  class NonRetriableError < RuntimeError
    attr_reader :cause

    KIND_LIMIT_REACHED      = 0
    KIND_REJECTED_BY_POLICY = 1
    KIND_BUDGET_EXHAUSTED   = 2

    # @param [String] message an error message
    # @param [Exception] cause a error cause
    def initialize(message:, kind:,  cause:)
      super(message)
      @cause = cause
      @kind = kind
    end

    # Is error limit reached
    def limit_reached?
      @kind == KIND_LIMIT_REACHED
    end

    # Is error was rejected by policy
    def rejected_by_policy?
      @kind == KIND_REJECTED_BY_POLICY
    end

    # Is error budget exhausted
    def budget_exhausted?
      @kind == KIND_BUDGET_EXHAUSTED
    end
  end
end
