require 'test_helper'

describe R4r::TokenBucket do
  it "a leaky bucket is leaky" do
    clock = new_clock
    bucket = R4r::LeakyTokenBucket.new(ttl_ms: 3 * 1000, reserve: 0, clock: clock)

    bucket.put(100)
    bucket.try_get(1).must_equal true

    clock.advance(seconds: 3)
    bucket.try_get(1).must_equal false
  end

  it "try_get fails when empty" do
    clock = new_clock
    bucket = R4r::LeakyTokenBucket.new(ttl_ms: 3 * 1000, reserve: 0, clock: clock)

    bucket.put(100)
    bucket.try_get(50).must_equal true
    bucket.try_get(49).must_equal true
    bucket.try_get(1).must_equal true

    bucket.try_get(1).must_equal false
    bucket.try_get(50).must_equal false

    bucket.put(1)
    bucket.try_get(2).must_equal false
    bucket.try_get(1).must_equal true
    bucket.try_get(1).must_equal false
  end

  it "provisions reserves" do
    clock = new_clock
    bucket = R4r::LeakyTokenBucket.new(ttl_ms: 3 * 1000, reserve: 100, clock: clock)

    # start at 0, though with 100 in reserve
    bucket.try_get(50).must_equal true # -50 + 100 = 0
    bucket.try_get(50).must_equal true # -100 + 100 = 0
    bucket.try_get(1).must_equal false # nope, at 0
    bucket.put(1) # now at -99 + 100 = 1
    bucket.try_get(1).must_equal true # back to 0

    clock.advance(seconds: 1)
    # This is what you get for eating
    # all of your candy right away.
    bucket.try_get(1).must_equal false # still at - 100 + 100 = 0

    clock.advance(seconds: 1)
    bucket.try_get(1).must_equal false # still at -100 + 100 = 0

    clock.advance(seconds: 1)
    bucket.try_get(1).must_equal false # still at -100 + 100 = 0

    clock.advance(seconds: 1)
    bucket.try_get(50).must_equal true # the -100 expires, so -50 + 100 = 50

    clock.advance(seconds: 3) # the -50 expired, so -100 + 100 = 0
    bucket.try_get(100).must_equal true
    bucket.try_get(1).must_equal false
  end

  private

  def new_clock
    R4r::FrozenClock.new
  end
end
