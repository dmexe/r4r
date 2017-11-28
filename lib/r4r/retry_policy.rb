module R4r

  # Pluggable retry strategy.
  #
  # @abstract
  class RetryPolicy
    # Check that given error can be retried or not.
    #
    # @param [Exception] error an error was occured
    # @param [Fixnum] num_retry a number of current retry, started from zero
    #
    # @return [Boolean] true if retry can be recovered
    def call(error:, num_retry:)
      raise NotImplementedError
    end

    # Creates a policy that always recover from any kind of errors.
    #
    # @return [R4r::RetryPolicy]
    def self.always
      ->(error:, num_retry:) { true }
    end

    # Creates a policy that never recover from any kind of errors.
    #
    # @return [R4r::RetryPolicy]
    def self.never
      ->(error:, num_retry:) { false }
    end

    # Creates a policy that recover from specified kind of errors
    #
    # @example
    #   R4r::RetryPolicy.instance_of(Some::Error, Service::Error)
    #
    # @return [R4r::RetryPolicy]
    def self.instance_of(*klass)
      R4r::InstanceOfRetryPolicy.new(klass: klass)
    end
  end

  # A retry policy that catch specified kind of errors
  class InstanceOfRetryPolicy < RetryPolicy
    # @param [Array[Class]] klass an error classes list that used for filtering
    def initialize(klass:)
      @klass = klass
    end

    # @return [Boolean]
    # @see R4r::RetryPolicy#call
    def call(error:, num_retry:)
      @klass.any? { |kind| error.is_a?(kind) }
    end
  end
end
