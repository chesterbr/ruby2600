require 'rubygems'
require 'humanize'
require 'timeout'

require 'ruby2600'
require 'support/shared_examples_for_bus.rb'
require 'support/shared_examples_for_cpu.rb'

include Ruby2600::Constants

RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_has_behavior, 'has behavior:'
  c.alias_it_should_behave_like_to :it_should, 'should'
end

def hex_word(word)
  sprintf("$%04X", word) rescue "$????"
end

def hex_byte(byte)
  sprintf("$%02X", byte) rescue "$??"
end
