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

  describe 'DEX' do
    before do
      cpu.memory = [0xCA] # DEX
      cpu.pc = 0x0000
    end

    describe '#fetch' do
      it 'should advance PC to the following instruction' do
        expect { cpu.fetch }.to change { cpu.pc }.by(1)
      end
    end

    describe '#execute' do
      context 'default' do
        before { cpu.x = 0x07 }

        it 'should decrease the x register' do
          cpu.execute

          cpu.x.should == 0x06
        end

        it 'should return the "time" (# of CPU cyles) it took to run the instruction' do
          cpu.execute.should == 2
        end

        it 'should not affect flags' do
          cpu.execute

          cpu.flags[:z].should be_false
          cpu.flags[:n].should be_false
        end
      end

      context 'zero result' do
        before { cpu.x = 0x01 }

        it 'should set the zero-flag' do
          cpu.execute

          cpu.flags[:z].should be_true
        end
      end

      context 'negative result' do
        before { cpu.x = 0x00 }

        it "should wrap around" do
          cpu.execute

          cpu.x.should == 0xFF # -1 in 8-bit two's complement
        end

        it 'should set the sign flag if negative' do
          cpu.execute

          cpu.flags[:n].should be_true
        end
      end
    end
  end
end
