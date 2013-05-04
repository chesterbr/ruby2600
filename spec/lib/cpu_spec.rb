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

  describe '#step' do
    context 'DEX' do
      before do
        cpu.memory = [0xCA] # DEX
        cpu.pc = 0x0000
        cpu.x = 0x07
      end

      it_should 'advance PC by one'

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

      it_should 'advance PC by one'

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

    context 'LDX' do
      before do
        cpu.pc = 0x0000
        cpu.memory = []
        cpu.memory[0x00A5] = 0x33
        cpu.memory[0x00B5] = 0x66
        cpu.memory[0x1234] = 0x99
        cpu.memory[0x1244] = 0xCC
        cpu.memory[0x1304] = 0xFF
      end

      context 'immediate' do
        before do
          cpu.memory[0..1] = [0xA2, 0x22] # LDX #$22
          cpu.flags[:z] = true
          cpu.flags[:n] = true
        end

        it_should 'advance PC by two'

        it_should 'take two cycles'

        it 'should set x value' do
          expect { cpu.step }.to change { cpu.x }.to(0x22)
        end

        it_should 'reset z flag'

        it_should 'reset n flag'
      end

      context 'zero page' do
        before do
          cpu.memory[0..1] = [0xA6, 0xA5] # LDX $A5
        end

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it 'should set x value' do
          expect { cpu.step }.to change { cpu.x }.to(0x33)
        end
      end

      context 'zero page, y' do
        before do
          cpu.memory[0..1] = [0xB6, 0xA5] # LDX $A5,Y
          cpu.y = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take four cycles'

        it 'should set x value' do
          expect { cpu.step }.to change { cpu.x }.to(0x66)
        end
      end

      context 'absolute' do
        before do
          cpu.memory[0..2] = [0xAC, 0x34, 0x12] # LDX $1234
          cpu.flags[:n] = false
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it 'should set x value' do
          expect { cpu.step }.to change { cpu.x }.to(0x99)
        end

        it_should 'set n flag'
      end

      context 'absolute, y' do
        before do
          cpu.memory[0..2] = [0xAC, 0x34, 0x12]  # 0000: LDX $1234,Y
          cpu.y = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it 'should set x value' do
          expect { cpu.step }.to change { cpu.x }.to(0xCC)
        end

        context 'crossing page boundary' do
          before { cpu.y = 0xD0 }

          it 'should set x value' do
            expect { cpu.step }.to change { cpu.x }.to(0xFF)
          end

          it_should 'take five cycles'
        end
      end

      # all should check if byte was picked up, and n/z flags
      # absolute, y should take 4cy, but cross-boundary 5



    end
  end
end
