# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'daemon_runner/version'

Gem::Specification.new do |spec|
  spec.name          = "daemon_runner"
  spec.version       = DaemonRunner::VERSION
  spec.authors       = ["Andrew Thompson"]
  spec.email         = ["Andrew_Thompson@rapid7.com"]

  spec.summary       = %q{Small library to make writing long running services easy}
  spec.homepage      = "https://github.com/rapid7/daemon_runner/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "logging", "~> 2.1"
  spec.add_dependency "mixlib-shellout", "~> 2.2"
  #spec.add_dependency "diplomat", "~> 1.0"
  spec.add_dependency "rufus-scheduler", "~> 3.2"
  spec.add_dependency "retryable", "~> 2.0"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "yard", "~> 0.8.7"
  spec.add_development_dependency "dev-consul", "~> 0.6.4"
end
