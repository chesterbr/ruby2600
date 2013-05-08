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
      # Some positions to play with
      cpu.memory = []
      cpu.memory[0x0002] = 0xFF
      cpu.memory[0x0005] = 0x11
      cpu.memory[0x0006] = 0x03
      cpu.memory[0x00A3] = 0xF5
      cpu.memory[0x00A4] = 0xFF
      cpu.memory[0x00A5] = 0x33
      cpu.memory[0x00A6] = 0x20
      cpu.memory[0x00B5] = 0x66
      cpu.memory[0x00B6] = 0x02
      cpu.memory[0x0266] = 0xA4
      cpu.memory[0x0311] = 0xB5
      cpu.memory[0x2043] = 0x77
      cpu.memory[0x2103] = 0x88
      cpu.memory[0x1234] = 0x99
      cpu.memory[0x1244] = 0xCC
      cpu.memory[0x1304] = 0xFF
      # Most examples will start at the top
      cpu.pc = 0x0000
    end

    context 'DEX' do
      before do
        cpu.memory[0] = 0xCA # DEX
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
        cpu.memory[0] = 0x88 # DEY
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

    context 'LDA' do
      context 'immediate' do
        before do
          cpu.memory[0..1] = 0xA9, 0x22 # LDA #$22
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
        before { cpu.memory[0..1] = 0xA5, 0xA5 } # LDA $A5

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'set a value', 0x33
      end

      context 'zero page, x' do
        before do
          cpu.memory[0..1] = 0xB5, 0xA5 # LDA $A5,X
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
          cpu.memory[0..2] = 0xAD, 0x34, 0x12 # LDA $1234
          cpu.flags[:n] = false
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set a value', 0x99

        it_should 'set n flag'
      end

      context 'absolute, x' do
        before do
          cpu.memory[0..2] = 0xBD, 0x34, 0x12  # 0000: LDA $1234,X
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
          before { cpu.memory[0..2] = 0xBD, 0xF5, 0xFF } # LDA $FFF5,X

          it_should 'set a value', 0x11
        end
      end

      context 'absolute, y' do
        before do
          cpu.memory[0..2] = 0xB9, 0x34, 0x12  # 0000: LDA $1234,Y
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
          before { cpu.memory[0..2] = 0xB9, 0xF5, 0xFF } # LDA $FFF5,Y

          it_should 'set a value', 0x11
        end
      end

      context '(indirect), y' do
        before do
          cpu.memory[0..1] = 0xB1, 0xA5  # 0000: LDA ($A5),Y
          cpu.y = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take five cycles'

        it_should 'set a value', 0x77

        context 'crossing page boundary' do
          before { cpu.y = 0xD0 }

          it_should 'set a value', 0x88

          it_should 'take six cycles'
        end

        context 'crossing memory boundary' do
          before { cpu.memory[0..1] = 0xB1, 0xA3}  # LDA ($A3),Y

          it_should 'set a value', 0x11
        end
      end

      context '(indirect, x)' do
        before do
          cpu.memory[0..1] = 0xA1, 0xA5  # 0000: LDA ($A5,X)
          cpu.x = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take six cycles'

        it_should 'set a value', 0xA4

        context 'crossing zero-page boundary' do
          before { cpu.x = 0x60 }

          it_should 'set a value', 0xB5
        end
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
        before { cpu.memory[0..1] = 0xA6, 0xA5 } # LDX $A5

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'set x value', 0x33
      end

      context 'zero page, y' do
        before do
          cpu.memory[0..1] = 0xB6, 0xA5 # LDX $A5,Y
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
          cpu.memory[0..2] = 0xAE, 0x34, 0x12 # LDX $1234
          cpu.flags[:n] = false
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set x value', 0x99

        it_should 'set n flag'
      end

      context 'absolute, y' do
        before do
          cpu.memory[0..2] = 0xBE, 0x34, 0x12 # LDX $1234,Y
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
          before { cpu.memory[0..2] = 0xBE, 0xF5, 0xFF } # LDX $FFF5,Y

          it_should 'set x value', 0x11
        end
      end
    end

    context 'LDY' do
      context 'immediate' do
        before do
          cpu.memory[0..1] = 0xA0, 0x22 # LDY #$22
          cpu.flags[:z] = true
          cpu.flags[:n] = true
        end

        it_should 'advance PC by two'

        it_should 'take two cycles'

        it_should 'set y value', 0x22

        it_should 'reset z flag'

        it_should 'reset n flag'
      end

      context 'zero page' do
        before { cpu.memory[0..1] = 0xA4, 0xA5 } # LDY $A5

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'set y value', 0x33
      end

      context 'zero page, x' do
        before do
          cpu.memory[0..1] = 0xB4, 0xA5 # LDY $A5,X
          cpu.x = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take four cycles'

        it_should 'set y value', 0x66

        context 'crossing zero-page boundary' do
          before { cpu.x = 0x60 }

          it_should 'set y value', 0x11
        end
      end

      context 'absolute' do
        before do
          cpu.memory[0..2] = 0xAC, 0x34, 0x12 # LDY $1234
          cpu.flags[:n] = false
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set y value', 0x99

        it_should 'set n flag'
      end

      context 'absolute, x' do
        before do
          cpu.memory[0..2] = 0xBC, 0x34, 0x12 # LDY $1234,X
          cpu.x = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set y value', 0xCC

        context 'crossing page boundary' do
          before { cpu.x = 0xD0 }

          it_should 'set y value', 0xFF

          it_should 'take five cycles'
        end

        context 'crossing memory boundary' do
          before { cpu.memory[0..2] = 0xBC, 0xF5, 0xFF } # LDY $FFF5,Y

          it_should 'set y value', 0x11
        end
      end
    end

    context 'STX' do
      before { cpu.x = 0x2F }

      context 'absolute' do
        before { cpu.memory[0..2] = 0x8E, 0x34, 0x12 } # STX $1234

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set memory with value', 0x1234, 0x2F
      end

      context 'zero page' do
        before do
          cpu.memory[0..1] = 0x86, 0xA5 # STX $A5
        end

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'set memory with value', 0x00A5, 0x2F
      end

      context 'zero page, y' do
        before do
          cpu.memory[0..1] = 0x96, 0xA5 # STX $A5,Y
          cpu.y = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take four cycles'

        it_should 'set memory with value', 0x00B5, 0x2F

        context 'crossing zero-page boundary' do
          before { cpu.y = 0x60 }

          it_should 'set memory with value', 0x0005, 0x2F
        end
      end
    end

    context 'STY' do
      before { cpu.y = 0x2F }

      context 'absolute' do
        before { cpu.memory[0..2] = 0x8C, 0x34, 0x12 } # STY $1234

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set memory with value', 0x1234, 0x2F
      end

      context 'zero page' do
        before do
          cpu.memory[0..1] = 0x84, 0xA5 # STY $A5
        end

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'set memory with value', 0x00A5, 0x2F
      end

      context 'zero page, y' do
        before do
          cpu.memory[0..1] = 0x94, 0xA5 # STY $A5,Y
          cpu.x = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take four cycles'

        it_should 'set memory with value', 0x00B5, 0x2F

        context 'crossing zero-page boundary' do
          before { cpu.x = 0x60 }

          it_should 'set memory with value', 0x0005, 0x2F
        end
      end
    end
  end
end
