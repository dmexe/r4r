require 'test_helper'

describe R4r::WindowedAdder do
  it "should sums things up when time stands still" do
    clock = new_clock
    adder = new_adder(clock)

    adder.incr
    adder.sum.must_equal 1

    clock.advance(seconds: 1)
    adder.add(2)
    adder.sum.must_equal 3

    clock.advance(seconds: 1)
    adder.incr
    adder.sum.must_equal 4

    clock.advance(seconds: 2)
    adder.sum.must_equal 1

    clock.advance(seconds: 100)
    adder.sum.must_equal 0

    adder.add(100)

    clock.advance(seconds: 1)
    adder.sum.must_equal 100

    adder.add(100)

    clock.advance(seconds: 1)
    adder.add(100)
    adder.sum.must_equal 300

    clock.advance(seconds: 100)
    adder.sum.must_equal 0
  end

  it "should maintains negative sums" do
    clock = new_clock
    adder = new_adder(clock)

    # net: 2
    adder.add(-2)
    adder.sum.must_equal(-2)

    adder.add(4)
    adder.sum.must_equal(2)

    # net: -4
    clock.advance(seconds: 1)
    adder.add(-2)
    adder.sum.must_equal(0)

    adder.add(-2)
    adder.sum.must_equal(-2)

    # net: -2
    clock.advance(seconds: 1)
    adder.add(-2)
    adder.sum.must_equal(-4)

    clock.advance(seconds: 1)
    adder.sum.must_equal(-6)

    clock.advance(seconds: 1)
    adder.sum.must_equal(-2)

    clock.advance(seconds: 1)
    adder.sum.must_equal(0)

    clock.advance(seconds: 100)
    adder.sum.must_equal(0)
  end

  private

  def new_clock
    R4r::FrozenClock.new
  end

  def new_adder(clock)
    R4r::WindowedAdder.new(range_ms: 3 * 1000, slices: 3, clock: clock)
  end
end

