require 'spec_helper'

describe Cpu do
  subject(:cpu) { Cpu.new }

  %w'z n'.each do |flag|
    it 'should initialize with a readable #{flag} flag' do
      expect { cpu.send(flag) }.to_not raise_error
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
      cpu.memory[0x1235] = 0xAA
      cpu.memory[0x1244] = 0xCC
      cpu.memory[0x1304] = 0xFF
      # Most examples will start at the top
      cpu.pc = 0x0000
    end

    context 'ADC' do
      pending 'not implemented'
    end

    context 'AND' do
      pending 'not implemented'
    end

    context 'ASL' do
      pending 'not implemented'
    end

    context 'BCC' do
      pending 'not implemented'
    end

    context 'BCS' do
      pending 'not implemented'
    end

    context 'BEQ' do
      pending 'not implemented'
    end

    context 'BIT' do
      pending 'not implemented'
    end

    context 'BMI' do
      pending 'not implemented'
    end

    context 'BNE' do
      pending 'not implemented'
    end

    context 'BPL' do
      pending 'not implemented'
    end

    context 'BRK' do
      pending 'not implemented'
    end

    context 'BVC' do
      pending 'not implemented'
    end

    context 'BVS' do
      pending 'not implemented'
    end

    context 'CLC' do
      pending 'not implemented'
    end

    context 'CLD' do
      pending 'not implemented'
    end

    context 'CLI' do
      pending 'not implemented'
    end

    context 'CLV' do
      pending 'not implemented'
    end

    context 'CMP' do
      pending 'not implemented'
    end

    context 'CPX' do
      pending 'not implemented'
    end

    context 'CPY' do
      pending 'not implemented'
    end

    context 'DEC' do
      pending 'not implemented'
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

      it_should 'reset Z flag'

      it_should 'reset N flag'

      context 'zero result' do
        before { cpu.x = 0x01 }

        it_should 'set Z flag'

        it_should 'reset N flag'
      end

      context 'negative result' do
        before { cpu.x = 0x00 }

        it "should wrap around to two's complement" do
          expect { cpu.step }.to change { cpu.x }.to(0xFF)
        end

        it_should 'reset Z flag'

        it_should 'set N flag'
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

      it_should 'reset Z flag'

      it_should 'reset N flag'

      context 'zero result' do
        before { cpu.y = 0x01 }

        it_should 'set Z flag'

        it_should 'reset N flag'
      end

      context 'negative result' do
        before { cpu.y = 0x00 }

        it "should wrap around to two's complement" do
          expect { cpu.step }.to change { cpu.y }.to(0xFF)
        end

        it_should 'reset Z flag'

        it_should 'set N flag'
      end
    end

    context 'EOR' do
      pending 'not implemented'
    end

    context 'INC' do
      pending 'not implemented'
    end

    context 'INX' do
      before do
        cpu.memory[0] = 0xE8 # INX
        cpu.x = 0x07
      end

      it_should 'advance PC by one'

      it_should 'take two cycles'

      it_should 'set X value', 0x08

      it_should 'reset Z flag'

      it_should 'reset N flag'

      context 'zero result' do
        before { cpu.x = 0xFF }

        it_should 'set Z flag'

        it_should 'reset N flag'

        it_should 'set X value', 0x00
      end

      context 'negative result' do
        before { cpu.x = 0xA0 }

        it_should 'reset Z flag'

        it_should 'set N flag'
      end
    end

    context 'INY' do
      before do
        cpu.memory[0] = 0xC8 # INX
        cpu.y = 0x07
      end

      it_should 'advance PC by one'

      it_should 'take two cycles'

      it_should 'set Y value', 0x08

      it_should 'reset Z flag'

      it_should 'reset N flag'

      context 'zero result' do
        before { cpu.y = 0xFF }

        it_should 'set Z flag'

        it_should 'reset N flag'

        it_should 'set Y value', 0x00
      end

      context 'negative result' do
        before { cpu.y = 0xA0 }

        it_should 'reset Z flag'

        it_should 'set N flag'
      end
    end

    context 'JMP' do
      context 'immediate' do
        before { cpu.memory[0..2] = 0x4C, 0x34, 0x12 } # JMP (1234)

        it_should 'set PC value', 0x1234

        it_should 'preserve flags'
      end

      context 'indirect' do
        before { cpu.memory[0..2] = 0x6C, 0x34, 0x12 } # JMP ($1234)

        it_should 'set PC value', 0xAA99

        it_should 'preserve flags'
      end

      context 'indirect mode bug' do
        pending 'not sure if will support'
      end
    end

    context 'JSR' do
      pending 'not implemented'
    end

    context 'LDA' do
      context 'immediate' do
        before do
          cpu.memory[0..1] = 0xA9, 0x22 # LDA #$22
          cpu.z = true
          cpu.n = true
        end

        it_should 'advance PC by two'

        it_should 'take two cycles'

        it_should 'set A value', 0x22

        it_should 'reset Z flag'

        it_should 'reset N flag'
      end

      context 'zero page' do
        before { cpu.memory[0..1] = 0xA5, 0xA5 } # LDA $A5

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'set A value', 0x33
      end

      context 'zero page, x' do
        before do
          cpu.memory[0..1] = 0xB5, 0xA5 # LDA $A5,X
          cpu.x = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take four cycles'

        it_should 'set A value', 0x66

        context 'crossing zero-page boundary' do
          before { cpu.x = 0x60 }

          it_should 'set A value', 0x11
        end
      end

      context 'absolute' do
        before do
          cpu.memory[0..2] = 0xAD, 0x34, 0x12 # LDA $1234
          cpu.n = false
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set A value', 0x99

        it_should 'set N flag'
      end

      context 'absolute, x' do
        before do
          cpu.memory[0..2] = 0xBD, 0x34, 0x12  # 0000: LDA $1234,X
          cpu.x = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set A value', 0xCC

        context 'crossing page boundary' do
          before { cpu.x = 0xD0 }

          it_should 'set A value', 0xFF

          it_should 'take five cycles'
        end

        context 'crossing memory boundary' do
          before { cpu.memory[0..2] = 0xBD, 0xF5, 0xFF } # LDA $FFF5,X

          it_should 'set A value', 0x11
        end
      end

      context 'absolute, y' do
        before do
          cpu.memory[0..2] = 0xB9, 0x34, 0x12  # 0000: LDA $1234,Y
          cpu.y = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set A value', 0xCC

        context 'crossing page boundary' do
          before { cpu.y = 0xD0 }

          it_should 'set A value', 0xFF

          it_should 'take five cycles'
        end

        context 'crossing memory boundary' do
          before { cpu.memory[0..2] = 0xB9, 0xF5, 0xFF } # LDA $FFF5,Y

          it_should 'set A value', 0x11
        end
      end

      context '(indirect), y' do
        before do
          cpu.memory[0..1] = 0xB1, 0xA5  # 0000: LDA ($A5),Y
          cpu.y = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take five cycles'

        it_should 'set A value', 0x77

        context 'crossing page boundary' do
          before { cpu.y = 0xD0 }

          it_should 'set A value', 0x88

          it_should 'take six cycles'
        end

        context 'crossing memory boundary' do
          before { cpu.memory[0..1] = 0xB1, 0xA3}  # LDA ($A3),Y

          it_should 'set A value', 0x11
        end
      end

      context '(indirect, x)' do
        before do
          cpu.memory[0..1] = 0xA1, 0xA5  # 0000: LDA ($A5,X)
          cpu.x = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take six cycles'

        it_should 'set A value', 0xA4

        context 'crossing zero-page boundary' do
          before { cpu.x = 0x60 }

          it_should 'set A value', 0xB5
        end
      end
    end

    context 'LDX' do
      context 'immediate' do
        before do
          cpu.memory[0..1] = [0xA2, 0x22] # LDX #$22
          cpu.z = true
          cpu.n = true
        end

        it_should 'advance PC by two'

        it_should 'take two cycles'

        it_should 'set X value', 0x22

        it_should 'reset Z flag'

        it_should 'reset N flag'
      end

      context 'zero page' do
        before { cpu.memory[0..1] = 0xA6, 0xA5 } # LDX $A5

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'set X value', 0x33
      end

      context 'zero page, y' do
        before do
          cpu.memory[0..1] = 0xB6, 0xA5 # LDX $A5,Y
          cpu.y = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take four cycles'

        it_should 'set X value', 0x66

        context 'crossing zero-page boundary' do
          before { cpu.y = 0x60 }

          it_should 'set X value', 0x11
        end
      end

      context 'absolute' do
        before do
          cpu.memory[0..2] = 0xAE, 0x34, 0x12 # LDX $1234
          cpu.n = false
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set X value', 0x99

        it_should 'set N flag'
      end

      context 'absolute, y' do
        before do
          cpu.memory[0..2] = 0xBE, 0x34, 0x12 # LDX $1234,Y
          cpu.y = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set X value', 0xCC

        context 'crossing page boundary' do
          before { cpu.y = 0xD0 }

          it_should 'set X value', 0xFF

          it_should 'take five cycles'
        end

        context 'crossing memory boundary' do
          before { cpu.memory[0..2] = 0xBE, 0xF5, 0xFF } # LDX $FFF5,Y

          it_should 'set X value', 0x11
        end
      end
    end

    context 'LDY' do
      context 'immediate' do
        before do
          cpu.memory[0..1] = 0xA0, 0x22 # LDY #$22
          cpu.z = true
          cpu.n = true
        end

        it_should 'advance PC by two'

        it_should 'take two cycles'

        it_should 'set Y value', 0x22

        it_should 'reset Z flag'

        it_should 'reset N flag'
      end

      context 'zero page' do
        before { cpu.memory[0..1] = 0xA4, 0xA5 } # LDY $A5

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'set Y value', 0x33
      end

      context 'zero page, x' do
        before do
          cpu.memory[0..1] = 0xB4, 0xA5 # LDY $A5,X
          cpu.x = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take four cycles'

        it_should 'set Y value', 0x66

        context 'crossing zero-page boundary' do
          before { cpu.x = 0x60 }

          it_should 'set Y value', 0x11
        end
      end

      context 'absolute' do
        before do
          cpu.memory[0..2] = 0xAC, 0x34, 0x12 # LDY $1234
          cpu.n = false
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set Y value', 0x99

        it_should 'set N flag'
      end

      context 'absolute, x' do
        before do
          cpu.memory[0..2] = 0xBC, 0x34, 0x12 # LDY $1234,X
          cpu.x = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set Y value', 0xCC

        context 'crossing page boundary' do
          before { cpu.x = 0xD0 }

          it_should 'set Y value', 0xFF

          it_should 'take five cycles'
        end

        context 'crossing memory boundary' do
          before { cpu.memory[0..2] = 0xBC, 0xF5, 0xFF } # LDY $FFF5,Y

          it_should 'set Y value', 0x11
        end
      end
    end

    context 'LSR' do
      pending 'not implemented'
    end

    context 'NOP' do
      pending 'not implemented'
    end

    context 'ORA' do
      pending 'not implemented'
    end

    context 'PHA' do
      pending 'not implemented'
    end

    context 'PHP' do
      pending 'not implemented'
    end

    context 'PLA' do
      pending 'not implemented'
    end

    context 'PLP' do
      pending 'not implemented'
    end

    context 'ROL' do
      pending 'not implemented'
    end

    context 'ROR' do
      pending 'not implemented'
    end

    context 'RTI' do
      pending 'not implemented'
    end

    context 'RTS' do
      pending 'not implemented'
    end

    context 'SBC' do
      pending 'not implemented'
    end

    context 'SEC' do
      pending 'not implemented'
    end

    context 'SED' do
      pending 'not implemented'
    end

    context 'SEI' do
      pending 'not implemented'
    end

    context 'STA' do
      before { cpu.a = 0x2F }

      context 'absolute' do
        before { cpu.memory[0..2] = 0x8D, 0x34, 0x12 } # STA $1234

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set memory with value', 0x1234, 0x2F

        it_should 'preserve flags'
      end

      context 'zero page' do
        before do
          cpu.memory[0..1] = 0x85, 0xA5 # STA $A5
        end

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'set memory with value', 0x00A5, 0x2F

        it_should 'preserve flags'
      end

      context 'zero page, x' do
        before do
          cpu.memory[0..1] = 0x95, 0xA5 # STA $A5,X
          cpu.x = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take four cycles'

        it_should 'set memory with value', 0x00B5, 0x2F

        it_should 'preserve flags'

        context 'crossing zero-page boundary' do
          before { cpu.x = 0x60 }

          it_should 'set memory with value', 0x0005, 0x2F
        end
      end

      context 'absolute, x' do
        before do
          cpu.memory[0..1] = 0x9D, 0x34, 0x12 # STA $FFF5
          cpu.x = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take five cycles'

        it_should 'set memory with value', 0x1244, 0x2F

        it_should 'preserve flags'

        context 'crossing memory boundary' do
          before { cpu.memory[0..2] = 0x9D, 0xF5, 0xFF } # STA $FFF5,X

          it_should 'set memory with value', 0x0005, 0x2F
        end
      end

      context 'absolute, y' do
        before do
          cpu.memory[0..1] = 0x99, 0x34, 0x12 # STA $1234
          cpu.y = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take five cycles'

        it_should 'set memory with value', 0x1244, 0x2F

        it_should 'preserve flags'

        context 'crossing memory boundary' do
          before { cpu.memory[0..2] = 0x99, 0xF5, 0xFF } # STA $FFF5,Y

          it_should 'set memory with value', 0x0005, 0x2F
        end
      end

      context '(indirect), y' do
        before do
          cpu.memory[0..1] = 0x91, 0xA5  # 0000: STA ($A5),Y
          cpu.y = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take six cycles'

        it_should 'set memory with value', 0x2043, 0x2F

        it_should 'preserve flags'

        context 'crossing page boundary' do
          before { cpu.y = 0xD0 }

          it_should 'set memory with value', 0x2103, 0x2F

          it_should 'take six cycles'
        end

        context 'crossing memory boundary' do
          before { cpu.memory[0..1] = 0x91, 0xA3}  # STA ($A3),Y

          it_should 'set memory with value', 0x0005, 0x2F
        end
      end

      context '(indirect, x)' do
        before do
          cpu.memory[0..1] = 0x81, 0xA5  # STA ($A5,X)
          cpu.x = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take six cycles'

        it_should 'set memory with value', 0x0266, 0x2F

        it_should 'preserve flags'

        context 'crossing zero-page boundary' do
          before { cpu.x = 0x60 }

          it_should 'take six cycles'

          it_should 'set memory with value', 0x0311, 0x2F
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

        it_should 'preserve flags'
      end

      context 'zero page' do
        before do
          cpu.memory[0..1] = 0x86, 0xA5 # STX $A5
        end

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'set memory with value', 0x00A5, 0x2F

        it_should 'preserve flags'
      end

      context 'zero page, y' do
        before do
          cpu.memory[0..1] = 0x96, 0xA5 # STX $A5,Y
          cpu.y = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take four cycles'

        it_should 'set memory with value', 0x00B5, 0x2F

        it_should 'preserve flags'

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

        it_should 'preserve flags'
      end

      context 'zero page' do
        before do
          cpu.memory[0..1] = 0x84, 0xA5 # STY $A5
        end

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'set memory with value', 0x00A5, 0x2F

        it_should 'preserve flags'
      end

      context 'zero page, y' do
        before do
          cpu.memory[0..1] = 0x94, 0xA5 # STY $A5,Y
          cpu.x = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take four cycles'

        it_should 'set memory with value', 0x00B5, 0x2F

        it_should 'preserve flags'

        context 'crossing zero-page boundary' do
          before { cpu.x = 0x60 }

          it_should 'set memory with value', 0x0005, 0x2F
        end
      end
    end

    context 'TAX' do
      pending 'not implemented'
    end

    context 'TAY' do
      pending 'not implemented'
    end

    context 'TSX' do
      pending 'not implemented'
    end

    context 'TXA' do
      pending 'not implemented'
    end

    context 'TXS' do
      pending 'not implemented'
    end

    context 'TYA' do
      pending 'not implemented'
    end
  end
end
