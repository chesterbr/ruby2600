# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruby2600/version'

Gem::Specification.new do |spec|
  spec.name          = "ruby2600"
  spec.version       = Ruby2600::VERSION
  spec.authors       = ["chesterbr"]
  spec.email         = ["cd@pobox.com"]
  spec.description   = <<-EOF
    Ruby2600 is a (work-in-progress) Atari 2600 emulator written in Ruby
  EOF
  spec.summary       = %q{Atari 2600 VCS emulator (WIP)}
  spec.homepage      = "http://github.com/chesterbr/ruby2600"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  if RUBY_PLATFORM == 'java'
    spec.add_dependency 'swt'
  else
    spec.add_runtime_dependency 'gosu'
    spec.add_dependency 'texplay', '~> 0.4.4.pre'

    spec.add_development_dependency 'pry-byebug'
    spec.add_development_dependency 'ruby-prof'
  end

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubygems-bundler'
  spec.add_development_dependency 'rspec', '~> 3.5.0'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'guard-bundler'
  spec.add_development_dependency 'humanize'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'simplecov-gem-adapter'
end
