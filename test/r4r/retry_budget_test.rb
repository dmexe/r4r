require 'test_helper'

describe R4r::RetryBudget do
  it "EmptyRetryBudget is empty" do
    rb = R4r::EmptyRetryBudget.new

    rb.balance.must_equal 0
    rb.try_withdraw.must_equal false

    rb.deposit
    rb.balance.must_equal 0
    rb.try_withdraw.must_equal false
  end

  it "InfiniteRetryBudget is infinite" do
    rb = R4r::InfiniteRetryBudget.new

    rb.balance.must_equal 100
    rb.try_withdraw.must_equal true
  end

  it "apply ttl_ms bounds check" do
    proc {
      R4r::RetryBudget.create(ttl_ms: 61 * 1000, min_retries_per_second: -1, percent_can_retry: 0.1)
    }.must_raise ArgumentError

    proc {
      R4r::RetryBudget.create(ttl_ms: 0, min_retries_per_second: -1, percent_can_retry: 0.1)
    }.must_raise ArgumentError
  end

  it "apply min_retries_per_second bounds check" do
    proc {
      R4r::RetryBudget.create(ttl_ms: 10 * 1000, min_retries_per_second: -1, percent_can_retry: 0.1)
    }.must_raise ArgumentError
  end

  it "apply percent_can_retry bounds check" do
    proc {
      R4r::RetryBudget.create(ttl_ms: 10 * 1000, min_retries_per_second: 0, percent_can_retry: -0.1)
    }.must_raise ArgumentError
  end

  it "apply min_retries_per_second=0 percent_can_retry=0 should be empty" do
    rb = R4r::RetryBudget.create(ttl_ms: 10 * 1000, min_retries_per_second: 0, percent_can_retry: 0.0)
    rb.must_be_instance_of R4r::EmptyRetryBudget
  end

  it "apply min_retries_per_second=0" do
    # every 10 reqs should give 1 retry
    test_budget(percent_can_retry: 0.1)

    # every 2 reqs should give 1 retry
    test_budget(percent_can_retry: 0.5)

    # every 4 reqs should give 1 retry
    test_budget(percent_can_retry: 0.25)

    # every 4 reqs should give 3 retries
    test_budget(percent_can_retry: 0.75)

    # high and and low percentages
    test_budget(percent_can_retry: 0.99)
    test_budget(percent_can_retry: 0.999)
    test_budget(percent_can_retry: 0.9999)
    test_budget(percent_can_retry: 0.01)
    test_budget(percent_can_retry: 0.001)
    test_budget(percent_can_retry: 0.0001)
  end

  it "apply min_retries_per_second=0 percent_can_retry greater than 1.0" do
    percent = 2.0
    rb = R4r::RetryBudget.create(min_retries_per_second: 0, percent_can_retry: percent)

    # check initial conditions
    rb.balance.must_equal 0
    rb.try_withdraw.must_equal false

    n_reqs = 10_000
    (0...n_reqs).each do
      rb.deposit
    end

    expected_retries = (n_reqs * percent).to_i
    expected_retries.must_equal rb.balance
  end

  it "apply with min_retries_per_second and percent_can_retry=0" do
    test_budget(ttl_ms: 1 * 1000, min_retries_per_second: 10, percent_can_retry: 0.0)
    test_budget(ttl_ms: 2 * 1000, min_retries_per_second: 5, percent_can_retry: 0.0)
  end

  it "apply with min_retries_per_second and percent_can_retry" do
    test_budget(ttl_ms: 1 * 1000, min_retries_per_second: 10, percent_can_retry: 0.1)
    test_budget(ttl_ms: 2 * 1000, min_retries_per_second: 5, percent_can_retry: 0.5)
  end

  private

  def new_clock
    R4r::FrozenClock.new
  end

  def test_budget(ttl_ms: 60 * 1000, min_retries_per_second: 0, percent_can_retry: 0.0)
    clock = new_clock
    rb = R4r::RetryBudget.create(
      ttl_ms: ttl_ms,
      min_retries_per_second: min_retries_per_second,
      percent_can_retry: percent_can_retry,
      clock: clock)

    min_retries = (ttl_ms.to_i / 1000) * min_retries_per_second
    min_retries.must_equal rb.balance

    if min_retries == 0
      rb.try_withdraw.must_equal false
    end

    n_reqs = 10_000
    retried = 0

    (0...n_reqs).each do |i|
      rb.deposit
      if rb.try_withdraw
        retried += 1
      else
        rb.balance.must_equal 0
      end
    end

    expected_retries = (n_reqs * percent_can_retry).to_i + min_retries

    ((retried - 1)..(retried + 1)).must_be :include?, expected_retries
  end
end
