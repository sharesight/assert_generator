# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'assert_generator/version'

Gem::Specification.new do |spec|
  spec.name          = 'assert_generator'
  spec.version       = AssertGenerator::VERSION
  spec.authors       = ['Richard Parratt']
  spec.email         = ['richard.parratt@sharesight.co.nz']

  spec.summary       = 'An assert generating gem.'
  spec.description   = <<~END_DESC
    Generate assert code from a result inside a unit or integration test.
    This is useful if you have code that you've spiked or eyeballed as 'working' and you'd like to produce some assertions,
    without editing the output of pretty-inspect manually or making it all up.
  END_DESC
  spec.license = 'MIT'

  spec.metadata['source_code_uri'] = 'https://github.com/sharesight/assert_generator'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir['lib/*.rb']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'mocha', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'shoulda', '~> 3.6'
  # spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'binding_of_caller'
  spec.add_development_dependency 'rubocop', '~> 0.76'
  spec.add_development_dependency 'simplecov', '~> 0.17', '>= 0.17.1'
end
