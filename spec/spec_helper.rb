require 'simplecov'
require 'simplecov-gem-adapter'
SimpleCov.start 'gem'

require 'rubygems'
require 'humanize'
require 'timeout'

require 'ruby2600'
require 'support/shared_examples_for_bus.rb'
require 'support/shared_examples_for_cpu.rb'
require 'support/shared_examples_for_riot.rb'
include Ruby2600::Constants

RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_has_behavior, 'has behavior:'
  c.alias_it_should_behave_like_to :it_should, 'should'
end

# Helper methods

def hex_word(word)
  sprintf("$%04X", word) rescue "$????"
end

def hex_byte(byte)
  sprintf("$%02X", byte) rescue "$??"
end

def rand_with_bit(bit, status)
  mask = 1 << bit
  status == :set ? mask | rand(256) : (0xFF ^ mask) & rand(256)
end

def path_for_ROM(name)
  "spec/fixtures/files/#{name}.bin"
end

