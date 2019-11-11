$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

if ENV['COVERAGE_ME']
  require 'simplecov'
  SimpleCov.start
end

require "assert_generator"

require "minitest/autorun"
require 'shoulda'
require 'mocha'
require 'mocha/minitest'

