# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fix_engine/version'

Gem::Specification.new do |spec|
  spec.name          = 'fix_engine'
  spec.version       = FixEngine::VERSION
  spec.authors       = ["Ivan Sidarau"]
  spec.email         = 'ivan.sidarau@gmail.com'
  spec.description   = "Fix Engine is a (minimalistic) implementation of the Financial Information eXchange with client-server multithread workarounds (based on pr-fix: https://github.com/uritu/pr-fix, by Joseph Dunn <joseph@magnesium.net> )."
  spec.summary       = "Fix Engine is a (minimalistic) implementation of the Financial Information eXchange (fix protocol)"
  spec.homepage      = 'http://github.com/sidorovis/fix_engine'
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "libxml-ruby"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end