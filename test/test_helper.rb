$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "r4r"

require "minitest/reporters"
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

#require "minitest/spec"
require "minitest/autorun"
