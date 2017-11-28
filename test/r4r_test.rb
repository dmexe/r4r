require "test_helper"

describe R4r do
  it "should have version number" do
    R4r::VERSION.wont_be :nil?
  end
end
