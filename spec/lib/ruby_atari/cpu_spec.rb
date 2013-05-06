require 'spec_helper'

describe Cpu do
  subject(:cpu) { Cpu.new }

  %w'z n'.each do |flag|
    it 'should initialize with a readable #{flag} flag' do
      expect { cpu.flags[flag.to_s] }.to_not raise_error
    end
  end

  %w'x y a'.each do |register|
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
    before do
      # Some values to allow testing for different addressing modes
      cpu.memory = []
      cpu.memory[0x0005] = 0x11
      cpu.memory[0x00A5] = 0x33
      cpu.memory[0x00B5] = 0x66
      cpu.memory[0x1234] = 0x99
      cpu.memory[0x1244] = 0xCC
      cpu.memory[0x1304] = 0xFF
      # We'll load most test snippets here
      cpu.pc = 0x0000
    end

    context 'DEX' do
      before do
        cpu.memory = [0xCA] # DEX
        cpu.x = 0x07
      end

      it_should 'advance PC by one'

      it_should 'take two cycles'

      it_should 'set x value', 0x06

      it_should 'reset z flag'

      it_should 'reset n flag'

      context 'zero result' do
        before { cpu.x = 0x01 }

        it_should 'set z flag'

        it_should 'reset n flag'
      end

      context 'negative result' do
        before { cpu.x = 0x00 }

        it_should 'set x value', 0xFF

        it_should 'reset z flag'

        it_should 'set n flag'
      end
    end

    context 'DEY' do
      before do
        cpu.memory = [0x88] # DEY
        cpu.y = 0x07
      end

      it_should 'advance PC by one'

      it_should 'take two cycles'

      it_should 'set y value', 0x06

      it_should 'reset z flag'

      it_should 'reset n flag'

      context 'zero result' do
        before { cpu.y = 0x01 }

        it_should 'set z flag'

        it_should 'reset n flag'
      end

      context 'negative result' do
        before { cpu.y = 0x00 }

        it_should 'set y value', 0xFF

        it_should 'reset z flag'

        it_should 'set n flag'
      end
    end

    context 'LDA' do
      context 'immediate' do
        before do
          cpu.memory[0..1] = [0xA9, 0x22] # LDA #$22
          cpu.flags[:z] = true
          cpu.flags[:n] = true
        end

        it_should 'advance PC by two'

        it_should 'take two cycles'

        it_should 'set a value', 0x22

        it_should 'reset z flag'

        it_should 'reset n flag'
      end

      context 'zero page' do
        before do
          cpu.memory[0..2] = [0xA5, 0xA5, 0xFF] # LDA $A5 (+junk)
        end

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'set a value', 0x33
      end

      context 'zero page, x' do
        before do
          cpu.memory[0..2] = [0xB5, 0xA5, 0xFF] # LDA $A5,X (+junk)
          cpu.x = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take four cycles'

        it_should 'set a value', 0x66

        context 'crossing zero-page boundary' do
          before { cpu.x = 0x60 }

          it_should 'set a value', 0x11
        end
      end

      context 'absolute' do
        before do
          cpu.memory[0..2] = [0xAD, 0x34, 0x12] # LDA $1234
          cpu.flags[:n] = false
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set a value', 0x99

        it_should 'set n flag'
      end

      context 'absolute, x' do
        before do
          cpu.memory[0..2] = [0xBD, 0x34, 0x12]  # 0000: LDA $1234,X
          cpu.x = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set a value', 0xCC

        context 'crossing page boundary' do
          before { cpu.x = 0xD0 }

          it_should 'set a value', 0xFF

          it_should 'take five cycles'
        end

        context 'crossing memory boundary' do
          before { cpu.memory[0..2] = 0xBD, 0xF5, 0xFF}  # LDA $FFF5,X

          it_should 'set a value', 0x11
        end
      end

      context 'absolute, y' do
        before do
          cpu.memory[0..2] = [0xB9, 0x34, 0x12]  # 0000: LDA $1234,Y
          cpu.y = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set a value', 0xCC

        context 'crossing page boundary' do
          before { cpu.y = 0xD0 }

          it_should 'set a value', 0xFF

          it_should 'take five cycles'
        end

        context 'crossing memory boundary' do
          before { cpu.memory[0..2] = 0xB9, 0xF5, 0xFF}  # LDA $FFF5,Y

          it_should 'set a value', 0x11
        end
      end

      context '(indirect), y' do
        pending 'should be tested'
      end

      context '(indirect, x)' do
        pending 'should be tested'
      end
    end

    context 'LDX' do
      context 'immediate' do
        before do
          cpu.memory[0..1] = [0xA2, 0x22] # LDX #$22
          cpu.flags[:z] = true
          cpu.flags[:n] = true
        end

        it_should 'advance PC by two'

        it_should 'take two cycles'

        it_should 'set x value', 0x22

        it_should 'reset z flag'

        it_should 'reset n flag'
      end

      context 'zero page' do
        before do
          cpu.memory[0..2] = [0xA6, 0xA5, 0xFF] # LDX $A5 (+junk)
        end

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'set x value', 0x33
      end

      context 'zero page, y' do
        before do
          cpu.memory[0..2] = [0xB6, 0xA5, 0xFF] # LDX $A5,Y (+junk)
          cpu.y = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take four cycles'

        it_should 'set x value', 0x66

        context 'crossing zero-page boundary' do
          before { cpu.y = 0x60 }

          it_should 'set x value', 0x11
        end
      end

      context 'absolute' do
        before do
          cpu.memory[0..2] = [0xAE, 0x34, 0x12] # LDX $1234
          cpu.flags[:n] = false
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set x value', 0x99

        it_should 'set n flag'
      end

      context 'absolute, y' do
        before do
          cpu.memory[0..2] = [0xBE, 0x34, 0x12]  # LDX $1234,Y
          cpu.y = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set x value', 0xCC

        context 'crossing page boundary' do
          before { cpu.y = 0xD0 }

          it_should 'set x value', 0xFF

          it_should 'take five cycles'
        end

        context 'crossing memory boundary' do
          before { cpu.memory[0..2] = 0xBE, 0xF5, 0xFF}  # LDX $FFF5,Y

          it_should 'set x value', 0x11
        end
      end

    end
  end
end
