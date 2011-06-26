# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "action_guard/version"

Gem::Specification.new do |s|
  s.name        = "action_guard"
  s.version     = ActionGuard::Version::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Rob Westgeest"]
  s.email       = "rob.westgeest@gmail.com"
  s.homepage    = "http://github.com/actionguard"
  s.summary     = "actionguard-#{ActionGuard::Version::STRING}"
  s.description = "authorisation of actions based on url-paths"

  s.rubygems_version   = "1.3.7"
  s.rubyforge_project  = "actionguard"

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {spec}/*`.split("\n")
  s.extra_rdoc_files = [ "README.md" ]
  s.rdoc_options     = ["--charset=UTF-8"]
  s.require_path     = "lib"
end

