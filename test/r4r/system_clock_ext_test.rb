require 'test_helper'

describe R4r::SystemClockExt do
  it "should get system time in millis" do
    tm1 = R4r::SystemClockExt.new.call
    tm2 = (Time.now.to_f * 1000).to_i
    diff = (tm1 - tm2).abs

    diff.must_be :<, 10
  end
end
