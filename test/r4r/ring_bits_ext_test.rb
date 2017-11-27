require "test_helper"

describe R4r::RingBitsExt do
  [1, 8, 16, 128, 2000, 4096, 5000].each do |size|
    it "should create a new instance with size=#{size}" do
      bs = R4r::RingBitsExt.new(size)
      bs.size.must_be :>=, size
      bs.size.must_be :<, size + 64
    end
  end

  [-1, 0].each do |size|
    it "should raise when pass invalid size=#{size}" do
      ->() { R4r::RingBitsExt.new(size) }.must_raise ArgumentError
    end
  end


  [2,3,5].each do |modulo|
    [5, 127, 2096, 3000].each do |size|
      it "should get values by capacity=#{size} modulo=#{modulo}" do
        bs = R4r::RingBitsExt.new(size)

        (0...size).each do |n|
          idx = bs.get(n)
          idx.must_equal false

          if (n % modulo == 0)
            prev = bs.set(n, true)
            prev.must_equal false
          end
        end

        (0...size).each do |n|
          if (n % modulo == 0)
            bs.get(n).must_equal true
          else
            bs.get(n).must_equal false
          end
        end
      end
    end
  end
end
