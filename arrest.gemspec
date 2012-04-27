# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "arrest/version"

Gem::Specification.new do |s|
  s.name        = "arrest"
  s.version     = Arrest::VERSION
  s.authors     = ["Axel Tetzlaff"]
  s.email       = ["axel.tetzlaff@fortytools.com"]
  s.homepage    = ""
  s.summary     = %q{Another ruby rest client}
  s.description = %q{Consume a rest API in a AR like fashion}

  s.rubyforge_project = "arrest"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "json"
  s.add_runtime_dependency "faraday", '>= 0.8.0'
  s.add_runtime_dependency "activemodel", '~> 3'

  s.add_development_dependency 'bundler', '>= 1.0.0'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'rspec', '~> 2'
  s.add_development_dependency 'rr'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rack'
end
