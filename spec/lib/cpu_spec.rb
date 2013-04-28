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

  describe '#next' do
    before do
      cpu.memory = [0xCA] # DEX
      cpu.pc = 0x0000
      cpu.x  = 0x07
    end

    it 'should execute an instruction' do
      cpu.next

      cpu.x.should == 0x06
    end

    it 'should advance PC to the following instruction' do
      expect { cpu.next }.to change { cpu.pc }.by(1)
    end

    it 'should return the "time" (# of CPU cyles) taken by an instruction' do
      cpu.next.should == 2
    end
  end
end
