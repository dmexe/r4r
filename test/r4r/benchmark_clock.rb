require 'bench_helper'

class ClockBenchmark < MiniTest::Benchmark
  def bench_ruby_time_in_millis
    assert_performance ->(x,y) { } do |n_reqs|
      (0..n_reqs).each do |n_req|
        (Time.now.to_f * 1000).to_i
      end
    end
  end

  def bench_ext_time_in_millis
    tm = R4r::SystemClockExt.new
    assert_performance ->(x,y) { } do |n_reqs|
      (0..n_reqs).each do |n_req|
        tm.call
      end
    end
  end
end
