require 'bundler'
Bundler.require

require 'opal'
require 'opal/rspec/rake_task'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

namespace :opal do
  desc "Build ruby2600.js"
  task :build do
    env = Opal::Environment.new
    env.append_path "bin"
    env.append_path "lib"

    File.open("ruby2600.js", "w+") do |out|
      out << env["ruby2600-opal"].to_s
    end
  end

  Opal.append_path File.expand_path('../lib', __FILE__)

  Opal::RSpec::RakeTask.new(:spec)
end

task :default => :spec
