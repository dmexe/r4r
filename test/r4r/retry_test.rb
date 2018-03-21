require 'test_helper'

describe R4r::Retry do
  it "should works without any errors" do
    rr = R4r::Retry.constant_backoff(num_retries: 3)
    rr.call { true }
  end

  it "should recover from an error" do
    rr = R4r::Retry.constant_backoff(num_retries: 3)
    recovered = 0

    result = rr.call do |n|
      if n < 2
        recovered += 1
        raise RuntimeError, "boom"
      end

      :result
    end

    expect(recovered).must_equal 2
    expect(result).must_equal :result
  end

  it "should pass through NonRetriableError" do
    rr = R4r::Retry.constant_backoff(num_retries: 3)

    expect {
      rr.call do |n|
        raise R4r::NonRetriableError.new(message: "-", kind: 0, cause: nil) if n == 0
      end
    }.must_raise R4r::NonRetriableError
  end

  it "should raise NonRetriableError when the policy cannot accept an exception" do
    rr = R4r::Retry.constant_backoff(num_retries: 3, policy: R4r::RetryPolicy.never)

    expect {
      rr.call do |n|
        raise RuntimeError if n == 0
      end
    }.must_raise R4r::NonRetriableError
  end

  it "should raise NonRetriableError when the budget is full" do
    rr = R4r::Retry.constant_backoff(num_retries: 3, budget: R4r::RetryBudget.empty)

    expect {
      rr.call do |n|
        raise RuntimeError if n == 0
      end
    }.must_raise R4r::NonRetriableError
  end

  it "should raise NonRetriableError when the retry limit reached" do
    rr = R4r::Retry.constant_backoff(num_retries: 3)
    recovered = 0

    expect {
      rr.call do |n|
        recovered += 1
        raise RuntimeError
      end
    }.must_raise R4r::NonRetriableError
    expect(recovered).must_equal(3)
  end
end
