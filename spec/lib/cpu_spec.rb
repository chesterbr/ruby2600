require 'spec_helper'

describe Cpu do
  subject(:cpu) { Cpu.new }

  describe '#reset' do
    before { cpu.memory = { 0xFFFC => 0x34, 0xFFFD => 0x12 } }

    it 'should boot at the address on the RESET vector ($FFFC)' do
      cpu.reset
      cpu.pc.should == 0x1234
    end
  end
end
