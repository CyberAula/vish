# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "delegates_attributes_to/version"

Gem::Specification.new do |s|
  s.name        = 'delegates_attributes_to'
  s.version     = DelegatesAttributesTo::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['David Faber', 'Pavel Gorbokon', 'Michael Guterl']
  s.email       = ['pahanix@gmail.com']
  s.homepage    = 'https://github.com/pahanix/delegates_attributes_to'
  s.summary     = %q{A rails plugin to allow delegation to ActiveRecord associations with dirty check and auto saving.}
  s.description = %q{Association attributes delegator plugin. It delegates association attributes accessors to a model. It also supports ActiveRecord::Dirty check, multiparamenter attributes (1i, 2i, 3i) assigning, auto saving for delegated attributes.}

  s.rubyforge_project = "delegates_attributes_to"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rspec',            '~> 1.3.0'
  s.add_development_dependency 'activerecord',     '~> 3.0.3'
  s.add_development_dependency 'database_cleaner', '~> 0.5.2'
  s.add_development_dependency 'sqlite3-ruby',     '~> 1.3.2'
end
