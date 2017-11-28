$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "r4r"

require "minitest/reporters"
require 'minitest/ci'
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require "minitest/autorun"
