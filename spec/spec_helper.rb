require 'rubygems'

require 'ruby_atari'
require 'support/shared_examples_for_memory.rb'
require 'support/shared_examples_for_cpu.rb'

RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_has_behavior, 'has behavior:'
  c.alias_it_should_behave_like_to :it_should, 'should'
end

def hex_word(word)
  sprintf("$%04X", word)
end

def hex_byte(byte)
  sprintf("$%02X", byte)
end
