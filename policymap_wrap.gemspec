# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name = %q{policymap_wrap}
  s.summary = %q{Ruby wrapper around the PolicyMap API v2}
  s.description = %q{Ruby wrapper around the PolicyMap API v2}
  s.homepage = %q{http://github.com/geminisbs/policymap_wrap}
  s.version = File.read(File.join(File.dirname(__FILE__), 'VERSION'))
  s.authors = ["Mauricio Gomes"]
  s.email = "mgomes@geminisbs.com"

  s.add_dependency "yajl-ruby", "~> 1.1.0"
  s.add_dependency "rest-client", "~> 1.8"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
