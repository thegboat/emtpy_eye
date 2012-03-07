# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "empty_eye/version"

Gem::Specification.new do |s|
  s.name        = "empty_eye"
  s.version     = EmptyEye::VERSION
  s.authors     = ["thegboat"]
  s.email       = ["gradygriffin@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Rails MTI gem}
  s.description = %q{Rails MTI gem powered by database views}

  s.rubyforge_project = "empty_eye"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    s.add_runtime_dependency('activerecord', '>= 2.3')
    s.add_development_dependency("rspec")
    s.add_development_dependency("mysql2")
  else
    s.add_dependency('activerecord', '>= 2.3')
    s.add_development_dependency("rspec")
    s.add_development_dependency("mysql2")
  end
end
