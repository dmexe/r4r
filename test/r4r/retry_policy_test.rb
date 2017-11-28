require 'test_helper'

describe R4r::RetryPolicy do
  it "RetryPolicy.always is always recovering" do
    policy = R4r::RetryPolicy.always

    expect(policy.call(error: nil, num_retry: 0)).must_equal true
  end

  it "RetryPolicy.never is never recovering" do
    policy = R4r::RetryPolicy.never

    expect(policy.call(error: nil, num_retry: 0)).must_equal false
  end

  it "InstanceOfRetryPolicy recover from given kind of errors" do
    policy = R4r::RetryPolicy.instance_of(BoomError1, BoomError2)

    expect(policy.call(error: BoomError1.new, num_retry: 0)).must_equal true
    expect(policy.call(error: BoomError2.new, num_retry: 0)).must_equal true
    expect(policy.call(error: RuntimeError.new, num_retry: 0)).must_equal false
  end

  BoomError1 = Class.new RuntimeError
  BoomError2 = Class.new RuntimeError
end
