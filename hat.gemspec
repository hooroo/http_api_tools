# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hat/version'

Gem::Specification.new do |spec|
  spec.name          = "hat"
  spec.version       = Hat::VERSION
  spec.authors       = ["Rob Monie"]
  spec.email         = ["robmonie@gmail.com"]
  spec.description   = %q{Hooroo API Tools - proper name tbd.}
  spec.summary       = %q{Provides JSON serialization/deserialization and basic model attribute definition for client apps}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "activesupport"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "ruby-prof"

end
