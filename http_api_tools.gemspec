# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'http_api_tools/version'

Gem::Specification.new do |spec|
  spec.name          = "http_api_tools"
  spec.version       = HttpApiTools::VERSION
  spec.authors       = ["Rob Monie"]
  spec.email         = ["robmonie@gmail.com"]
  spec.description   = %q{Http API Tools}
  spec.summary       = %q{Provides JSON serialization/deserialization and basic model attribute definition for client apps}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "activesupport", '~> 4.1'
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "ruby-prof"

end
