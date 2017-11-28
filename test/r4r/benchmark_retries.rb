require 'bench_helper'

class RetriesBenchmark < MiniTest::Benchmark
  def bench_retry_call
    assert_performance ->(x,y) { } do |n_reqs|
      rd = R4r::Retries.new(num_retries: 3)
      (0..n_reqs).each do |n_req|
        rd.call do |num_retry|
          true
        end
      end
    end
  end

  def bench_just_call
    assert_performance ->(x,y) { } do |n_reqs|
      (0..n_reqs).each do |n_req|
        true
      end
    end
  end
end
