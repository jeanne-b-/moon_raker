# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'moon_raker/version'

Gem::Specification.new do |s|
  s.name        = 'moon_raker'
  s.version     = MoonRaker::VERSION
  s.authors     = ["Pavel Pokorny","Ivan Necas"]
  s.email       = ["pajkycz@gmail.com", "inecas@redhat.com"]
  s.homepage    = "http://github.com/lambda2/moon_raker"
  s.summary     = %q{Rails REST API documentation tool}
  s.description = %q{Rails REST API documentation tool}


  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ['lib']

  s.add_development_dependency 'rails', '>= 3.0.20'
  s.add_dependency 'json'
  s.add_dependency 'meta-tags'
  s.add_development_dependency "rspec-rails", "~> 3.0"
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'maruku'
  s.add_development_dependency 'RedCloth'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc'

end
