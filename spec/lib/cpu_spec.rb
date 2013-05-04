require 'spec_helper'

describe Cpu do
  subject(:cpu) { Cpu.new }

  %w'z n'.each do |flag|
    it 'should initialize with a readable #{flag} flag' do
      expect { cpu.flags[flag.to_s] }.to_not raise_error
    end
  end

  %w'x y'.each do |register|
    it "should initialize with a byte-size #{register} register" do
      (0..255).should cover(cpu.send(register))
    end
  end

  describe '#reset' do
    before { cpu.memory = { 0xFFFC => 0x34, 0xFFFD => 0x12 } }

    it 'should boot at the address on the RESET vector ($FFFC)' do
      cpu.reset

      cpu.pc.should == 0x1234
    end
  end

  shared_examples_for 'advance PC by' do |instruction_size|
    it { expect { cpu.step }.to change { cpu.pc }.by(instruction_size) }
  end

  describe '#step' do
    context 'DEX' do
      before do
        cpu.memory = [0xCA] # DEX
        cpu.pc = 0x0000
        cpu.x = 0x07
      end

      it_should 'advance PC by', 1

      it_should 'take two cycles'

      it 'should decrease value' do
        expect { cpu.step }.to change { cpu.x }.by(-1)
      end

      it_should 'reset z flag'

      it_should 'reset n flag'

      context 'zero result' do
        before { cpu.x = 0x01 }

        it_should 'set z flag'

        it_should 'reset n flag'
      end

      context 'negative result' do
        before { cpu.x = 0x00 }

        it "should wrap around to two's complement" do
          expect { cpu.step }.to change { cpu.x }.to(0xFF)
        end

        it_should 'reset z flag'

        it_should 'set n flag'
      end
    end

    context 'DEY' do
      before do
        cpu.memory = [0x88] # DEY
        cpu.pc = 0x0000
        cpu.y = 0x07
      end

      it_should 'advance PC by', 1

      it_should 'take two cycles'

      it 'should decrease value' do
        expect { cpu.step }.to change { cpu.y }.by(-1)
      end

      it_should 'reset z flag'

      it_should 'reset n flag'

      context 'zero result' do
        before { cpu.y = 0x01 }

        it_should 'set z flag'

        it_should 'reset n flag'
      end

      context 'negative result' do
        before { cpu.y = 0x00 }

        it "should wrap around to two's complement" do
          expect { cpu.step }.to change { cpu.y }.to(0xFF)
        end

        it_should 'reset z flag'

        it_should 'set n flag'
      end
    end
  end
end
