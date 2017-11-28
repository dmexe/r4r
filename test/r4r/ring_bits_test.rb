require 'test_helper'

describe R4r::RingBits do
  it "should create a new instance" do
    bs = R4r::RingBits.new(size: 4)
    bs.size.must_equal(4)
  end

  it "should set values" do
    bs = R4r::RingBits.new(size: 4)

    expect(bs.index).must_equal(-1)
    expect(bs.set_next(true)).must_equal(1)

    expect(bs.index).must_equal(0)
    expect(bs.set_next(false)).must_equal(1)

    expect(bs.index).must_equal(1)
    expect(bs.set_next(true)).must_equal(2)

    expect(bs.index).must_equal(2)
    expect(bs.set_next(true)).must_equal(3)

    expect(bs.index).must_equal(3)
    expect(bs.set_next(false)).must_equal(2)

    expect(bs.index).must_equal(0)
    expect(bs.set_next(false)).must_equal(2)

    expect(bs.index).must_equal(1)
    expect(bs.cardinality).must_equal(2)
  end

  it "should set values with less capacity" do
    bs = R4r::RingBits.new(size: 100)
    expected_cardinality = 0

    (0..1000)
      .map { |idx| [idx, [true, false].sample] }
      .map { |pair|
        idx, value = pair
        bs.set_next(value)
        if (idx > 900 && value)
          expected_cardinality += 1
        end
      }

    expect(bs.cardinality).must_equal(expected_cardinality)
    expect(bs.bit_set_size).must_equal(128)
    expect(bs.length).must_equal(100)
  end
end
