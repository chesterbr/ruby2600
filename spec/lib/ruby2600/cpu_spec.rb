require 'spec_helper'

describe Ruby2600::CPU do
  subject(:cpu) { Ruby2600::CPU.new }

  CPU_FLAGS.each do |flag|
    it 'should initialize with a readable #{flag} flag' do
      expect { cpu.send(flag) }.to_not raise_error
    end
  end

  %w'x y a s'.each do |register|
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
      # Most examples will run a single opcode from here
      cpu.pc = 0x0000

      # Catch unexpected side effects
      randomize :a, :x, :y, :s, :n, :v, :i, :z, :c

      # Examples wil refer to these values. Add, but don't change!
      cpu.memory = []
      cpu.memory[0x0001] = 0xFE
      cpu.memory[0x0002] = 0xFF
      cpu.memory[0x0005] = 0x11
      cpu.memory[0x0006] = 0x03
      cpu.memory[0x0007] = 0x54
      cpu.memory[0x000E] = 0xAC
      cpu.memory[0x0010] = 0x53
      cpu.memory[0x0011] = 0xA4
      cpu.memory[0x00A3] = 0xF5
      cpu.memory[0x00A4] = 0xFF
      cpu.memory[0x00A5] = 0x33
      cpu.memory[0x00A6] = 0x20
      cpu.memory[0x00A7] = 0x01
      cpu.memory[0x00A8] = 0xFE
      cpu.memory[0x00A9] = 0xFF
      cpu.memory[0x00B5] = 0x66
      cpu.memory[0x00B6] = 0x02
      cpu.memory[0x0151] = 0xB7
      cpu.memory[0x0160] = 0xFF
      cpu.memory[0x0161] = 0x77
      cpu.memory[0x0266] = 0xA4
      cpu.memory[0x0311] = 0xB5
      cpu.memory[0x1122] = 0x07
      cpu.memory[0x1234] = 0x99
      cpu.memory[0x1235] = 0xAA
      cpu.memory[0x1244] = 0xCC
      cpu.memory[0x1304] = 0xFF
      cpu.memory[0x1314] = 0x00
      cpu.memory[0x1315] = 0xFF
      cpu.memory[0x1316] = 0x80
      cpu.memory[0x2043] = 0x77
      cpu.memory[0x2103] = 0x88
    end

    def randomize(*attrs)
      attrs.each do |attr|
        value = attr =~ /[axys]/ ? rand(256) : [true, false].sample
        cpu.send "#{attr}=", value
      end
    end

    # Ensuring we deal well with page crossing and memory wraping

    it_should 'work on any memory position' do
      let(:code) { [0xEA] } # NOP
      let(:expected_a) { nil }
    end

    it_should 'work on any memory position' do
      let(:code) { [0xA9, 0x03] } # LDA #$03
      let(:expected_a) { 0x03 }
    end

    it_should 'work on any memory position' do
      let(:code) { [0xAD, 0x34, 0x12] } # LDA $1234
      let(:expected_a) { 0x99 }
    end

    # Full 650x instruction set

    context 'ADC' do
      before do
        cpu.a = 0xAC
        cpu.c = false
        cpu.d = false
      end

      context 'immediate' do
        before { cpu.memory[0..1] = 0x69, 0x22 } # ADC #$22

        it_should 'advance PC by two'

        it_should 'take two cycles'

        it_should 'set A value', 0xCE

        it_should 'reset Z flag'

        it_should 'set N flag'

        it_should 'reset C flag'

        it_should 'reset V flag'

        context 'with_carry' do
          before { cpu.c = true }

          it_should 'set A value', 0xCF

          it_should 'reset C flag'
        end

        # http://www.6502.org/tutorials/vflag.html
        context 'Bruce Clark paper tests' do
          it_should 'add and set A/C/V', 0x01, 0x01, 0x02, false, false
          it_should 'add and set A/C/V', 0x01, 0xFF, 0x00, true, false
          it_should 'add and set A/C/V', 0x7F, 0x01, 0x80, false, true
          it_should 'add and set A/C/V', 0x80, 0xFF, 0x7F, true, true
        end

        context '2 - 10 = -8; no carry/overflow' do
          it_should 'add and set A/C/V', 0x02, 0xF6, 0xF8, false, false
        end

        context 'decimal mode' do
          before { cpu.d = true }

          context 'result <= 99' do
            before { cpu.a = 0x19 }

            it_should 'set A value', 0x41

            it_should 'reset C flag'
          end

          context 'result > 99' do
            before { cpu.a = 0x78 }

            it_should 'set A value', 0x00

            it_should 'set C flag'
          end
        end
      end

      context 'zero page' do
        before { cpu.memory[0..1] = 0x65, 0xA4 } # ADC $A4

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'set A value', 0xAB

        it_should 'set N flag'

        it_should 'set C flag'

        it_should 'reset V flag'
      end

      context 'zero page, x' do
        before do
          cpu.memory[0..1] = 0x75, 0xA5 # ADC $A5,X
          cpu.x = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take four cycles'

        it_should 'set A value', 0x12

        it_should 'set C flag'

        context 'wrapping zero-page boundary' do
          before { cpu.x = 0x62 }

          it_should 'set A value', 0x00

          it_should 'set C flag'

          it_should 'set Z flag'
        end
      end

      context 'absolute' do
        before do
          cpu.memory[0..2] = 0x6D, 0x34, 0x12 # ADC $1234
          cpu.n = false
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set A value', 0x45

        it_should 'set C flag'
      end

      context 'absolute, x' do
        before do
          cpu.memory[0..2] = 0x7D, 0x34, 0x12  # ADC $1234,X
          cpu.x = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set A value', 0x78

        context 'crossing page boundary' do
          before { cpu.x = 0xD0 }

          it_should 'set A value', 0xAB

          it_should 'take five cycles'
        end

        context 'wrapping memory' do
          before { cpu.memory[0..2] = 0x7D, 0xF5, 0xFF } # ADC $FFF5,X

          it_should 'set A value', 0xBD
        end
      end

      context 'absolute, y' do
        before do
          cpu.memory[0..2] = 0x79, 0x34, 0x12  # ADC $1234,Y
          cpu.y = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set A value', 0x78

        context 'crossing page boundary' do
          before { cpu.y = 0xD0 }

          it_should 'set A value', 0xAB

          it_should 'take five cycles'
        end

        context 'wrapping memory' do
          before { cpu.memory[0..2] = 0x79, 0xF5, 0xFF } # ADC $FFF5,Y

          it_should 'set A value', 0xBD
        end
      end

      context '(indirect, x)' do
        before do
          cpu.memory[0..1] = 0x61, 0xA5  # ADC ($A5,X)
          cpu.x = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take six cycles'

        it_should 'set A value', 0x50

        context 'wrapping around zero-page' do
          before { cpu.x = 0x60 }

          it_should 'set A value', 0x61
        end
      end

      context '(indirect), y' do
        before do
          cpu.memory[0..1] = 0x71, 0xA5  # ADC ($A5),Y
          cpu.y = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take five cycles'

        it_should 'set A value', 0x23

        context 'crossing page boundary' do
          before { cpu.y = 0xD0 }

          it_should 'set A value', 0x34

          it_should 'take six cycles'
        end

        context 'wrapping memory' do
          before { cpu.memory[0..1] = 0x71, 0xA3}  # ADC ($A3),Y

          it_should 'set A value', 0xBD
        end
      end
    end

    context 'AND' do
      before { cpu.a = 0b10101100 } # #$AC

      context 'immediate' do
        before { cpu.memory[0..1] = 0x29, 0x22 } # AND #$22

        it_should 'advance PC by two'

        it_should 'take two cycles'

        it_should 'set A value', 0x20

        it_should 'reset Z flag'

        it_should 'reset N flag'
      end

      context 'zero page' do
        before { cpu.memory[0..1] = 0x25, 0xA4 } # AND $A4

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'set A value', 0xAC
      end

      context 'zero page, x' do
        before do
          cpu.memory[0..1] = 0x35, 0xA5 # AND $A5,X
          cpu.x = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take four cycles'

        it_should 'set A value', 0x24

        context 'wrapping around zero-page' do
          before { cpu.x = 0x60 }

          it_should 'set A value', 0x00

          it_should 'set Z flag'
        end
      end

      context 'absolute' do
        before do
          cpu.memory[0..2] = 0x2D, 0x34, 0x12 # AND $1234
          cpu.n = false
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set A value', 0x88

        it_should 'set N flag'
      end

      context 'absolute, x' do
        before do
          cpu.memory[0..2] = 0x3D, 0x34, 0x12  # AND $1234,X
          cpu.x = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set A value', 0x8C

        context 'crossing page boundary' do
          before { cpu.x = 0xD0 }

          it_should 'set A value', 0xAC

          it_should 'take five cycles'
        end

        context 'wrapping memory' do
          before { cpu.memory[0..2] = 0x3D, 0xF5, 0xFF } # AND $FFF5,X

          it_should 'set A value', 0x00
        end
      end

      context 'absolute, y' do
        before do
          cpu.memory[0..2] = 0x39, 0x34, 0x12  # AND $1234,Y
          cpu.y = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set A value', 0x8C

        context 'crossing page boundary' do
          before { cpu.y = 0xD0 }

          it_should 'set A value', 0xAC

          it_should 'take five cycles'
        end

        context 'wrapping memory' do
          before { cpu.memory[0..2] = 0x39, 0xF5, 0xFF } # AND $FFF5,Y

          it_should 'set A value', 0x0
        end
      end

      context '(indirect, x)' do
        before do
          cpu.memory[0..1] = 0x21, 0xA5  # AND ($A5,X)
          cpu.x = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take six cycles'

        it_should 'set A value', 0xA4

        context 'wrapping around zero-page' do
          before { cpu.x = 0x60 }

          it_should 'set A value', 0xA4
        end
      end

      context '(indirect), y' do
        before do
          cpu.memory[0..1] = 0x31, 0xA5  # AND ($A5),Y
          cpu.y = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take five cycles'

        it_should 'set A value', 0x24

        context 'crossing page boundary' do
          before { cpu.y = 0xD0 }

          it_should 'set A value', 0x88

          it_should 'take six cycles'
        end

        context 'wrapping memory' do
          before { cpu.memory[0..1] = 0x31, 0xA3}  # AND ($A3),Y

          it_should 'set A value', 0x00
        end
      end
    end

    context 'ASL' do
      context 'accumulator' do
        before do
          cpu.memory[0] = 0x0A # ASL A
          cpu.a = 0b11101110
        end

        it_should 'advance PC by one'

        it_should 'take two cycles'

        it_should 'set A value', 0b11011100

        it_should 'reset Z flag'

        it_should 'set C flag'

        it_should 'set N flag'

        context 'carry set' do
          before { cpu.c = true }

          it_should 'set A value', 0b11011100 # carry does not affect ASL
        end
      end

      context 'zero page' do
        before { cpu.memory[0..1] = 0x06, 0xA7 } # ASL $A7

        it_should 'advance PC by two'

        it_should 'take five cycles'

        it_should 'set memory with value', 0x00A7, 0x02

        it_should 'reset N flag'

        it_should 'reset C flag'

        it_should 'reset Z flag'
      end

      context 'zero page, x' do
        before do
          cpu.memory[0..1] = 0x16, 0xA5  # ASL $A5,X
          cpu.x = 0x11
        end

        it_should 'advance PC by two'

        it_should 'take six cycles'

        it_should 'set memory with value', 0x00B6, 0x04

        it_should 'reset N flag'

        it_should 'reset C flag'

        it_should 'reset Z flag'
      end

      context 'absolute' do
        before { cpu.memory[0..2] = 0x0E, 0x04, 0x13 } # ASL $1304

        it_should 'advance PC by three'

        it_should 'take six cycles'

        it_should 'set memory with value', 0x1304, 0xFE

        it_should 'set N flag'

        it_should 'set C flag'

        it_should 'reset Z flag'
      end

      context 'absolute, x' do
        before do
          cpu.memory[0..2] = 0x1E, 0x04, 0x13 # ASL $1304,X
          cpu.x = 0x12
        end

        it_should 'advance PC by three'

        it_should 'take seven cycles'

        it_should 'set memory with value', 0x1316, 0x00

        it_should 'reset N flag'

        it_should 'set C flag'

        it_should 'set Z flag'
      end
    end

    context 'BCC' do
      it_should_behave_like 'a branch instruction' do
        let(:opcode) { 0x90 }
        let(:flag) { :c }
        let(:branch_state) { false }
      end
    end

    context 'BCS' do
      it_should_behave_like 'a branch instruction' do
        let(:opcode) { 0xB0 }
        let(:flag) { :c }
        let(:branch_state) { true }
      end
    end

    context 'BEQ' do
      it_should_behave_like 'a branch instruction' do
        let(:opcode) { 0xF0 }
        let(:flag) { :z }
        let(:branch_state) { true }
      end
    end

    context 'BIT' do
      before { cpu.a = 0b10101100 } # #$AC

      context 'zero page' do
        before { cpu.memory[0..1] = 0x24, 0x11 } # BIT $11

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'set N flag'

        it_should 'reset Z flag'

        it_should 'reset V flag'

        it { expect{ cpu.step }.to_not change{ cpu.a } }

        context 'resulting in bit 6 set' do
          before do
            cpu.memory[0..1] = 0x24, 0xA4 # BIT $A4
            cpu.a = 0x70
          end

          it_should 'set V flag'
        end

        context 'resulting in zero' do
          before do
            cpu.memory[0..1] = 0x24, 0x10 # BIT $10
          end

          it_should 'set Z flag'
        end
      end

      context 'absolute' do
        before { cpu.memory[0..2] = 0x2C, 0x22, 0x11 } # BIT $1122

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'reset N flag'

        it_should 'reset V flag'

        it_should 'reset Z flag'
      end
    end

    context 'BMI' do
      it_should_behave_like 'a branch instruction' do
        let(:opcode) { 0x30 }
        let(:flag) { :n }
        let(:branch_state) { true }
      end
    end

    context 'BNE' do
      it_should_behave_like 'a branch instruction' do
        let(:opcode) { 0xD0 }
        let(:flag) { :z }
        let(:branch_state) { false }
      end
    end

    context 'BPL' do
      it_should_behave_like 'a branch instruction' do
        let(:opcode) { 0x10 }
        let(:flag) { :n }
        let(:branch_state) { false }
      end
    end

    context 'BRK' do
      before do
        cpu.memory[0x1234] = 0x00 # BRK
        cpu.memory[0xFFFE..0xFFFF] = 0x89, 0x67 # Interrupt vector
        cpu.pc = 0x1234
        cpu.s = 0xF0
      end

      it_should 'take seven cycles'

      it_should 'set memory with value', 0x01F0, 0x12
      it_should 'set memory with value', 0x01EF, 0x35

      it_should 'set S value', 0xED

      it_should 'set PC value', 0x6789

      it_should 'set I flag'

      it_should 'set memory with P for various flag values', 0x01EE
    end

    context 'BVC' do
      it_should_behave_like 'a branch instruction' do
        let(:opcode) { 0x50 }
        let(:flag) { :v }
        let(:branch_state) { false }
      end
    end

    context 'BVS' do
      it_should_behave_like 'a branch instruction' do
        let(:opcode) { 0x70 }
        let(:flag) { :v }
        let(:branch_state) { true }
      end
    end

    context 'CLC' do
      before {
        cpu.memory[0] = 0x18 # SEC
        cpu.c = true
      }

      it_should 'reset C flag'
    end

    context 'CLD' do
      before {
        cpu.memory[0] = 0xD8 # CLD
        cpu.d = true
      }

      it_should 'reset D flag'
    end

    context 'CLI' do
      before {
        cpu.memory[0] = 0x58 # CLI
        cpu.i = true
      }

      it_should 'reset I flag'
    end

    context 'CLV' do
      before {
        cpu.memory[0] = 0xB8 # CLV
        cpu.v = true
      }

      it_should 'reset V flag'
    end

    context 'CMP' do
      before { cpu.a = 0xAC }

      context 'immediate' do
        before { cpu.memory[0..1] = 0xC9, 0x22 } # CMP #$22

        it_should 'advance PC by two'

        it_should 'take two cycles'

        it_should 'reset Z flag'

        it_should 'set N flag'

        it_should 'set C flag'

        pending 'Z FLAG TEST'
      end

      context 'zero page' do
        before { cpu.memory[0..1] = 0xC5, 0xA4 } # CMP $A4

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'set N flag'

        it_should 'reset C flag'
      end

      context 'zero page, x' do
        before do
          cpu.memory[0..1] = 0xD5, 0xA5 # CMP $A5,X
          cpu.x = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take four cycles'

        it_should 'set C flag'

        context 'wrapping zero-page boundary' do
          before { cpu.x = 0x62 }

          it_should 'reset N flag'

          it_should 'set C flag'
        end
      end

      context 'absolute' do
        before do
          cpu.memory[0..2] = 0xCD, 0x34, 0x12 # CMP $1234
          cpu.n = false
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'reset N flag'

        it_should 'set C flag'
      end

      context 'absolute, x' do
        before do
          cpu.memory[0..2] = 0xDD, 0x34, 0x12  # CMP $1234,X
          cpu.x = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set N flag'

        it_should 'reset C flag'

        context 'crossing page boundary' do
          before { cpu.x = 0xD0 }

          it_should 'set N flag'

          it_should 'reset C flag'

          it_should 'take five cycles'
        end

        context 'wrapping memory' do
          before { cpu.memory[0..2] = 0xDD, 0xF5, 0xFF } # CMP $FFF5,X

          it_should 'set N flag'

          it_should 'set C flag'
        end
      end

      context 'absolute, y' do
        before do
          cpu.memory[0..2] = 0xD9, 0x34, 0x12  # CMP $1234,Y
          cpu.y = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set N flag'

        it_should 'reset C flag'

        context 'crossing page boundary' do
          before { cpu.y = 0xD0 }

          it_should 'set N flag'

          it_should 'reset C flag'

          it_should 'take five cycles'
        end

        context 'wrapping memory' do
          before { cpu.memory[0..2] = 0xD9, 0xF5, 0xFF } # CMP $FFF5,Y

          it_should 'set N flag'

          it_should 'set C flag'
        end
      end

      context '(indirect, x)' do
        before do
          cpu.memory[0..1] = 0xC1, 0xA5  # CMP ($A5,X)
          cpu.x = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take six cycles'

        context 'wrapping around zero-page' do
          before { cpu.x = 0x60 }

          it_should 'set N flag'

          it_should 'reset C flag'
        end
      end

      context '(indirect), y' do
        before do
          cpu.memory[0..1] = 0xD1, 0xA5  # CMP ($A5),Y
          cpu.y = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take five cycles'

        it_should 'reset N flag'

        it_should 'set C flag'

        context 'crossing page boundary' do
          before { cpu.y = 0xD0 }

          it_should 'reset N flag'

          it_should 'set C flag'

          it_should 'take six cycles'
        end

        context 'wrapping memory' do
          before { cpu.memory[0..1] = 0xD1, 0xA8}  # CMP ($A8),Y

          it_should 'reset N flag'

          it_should 'set C flag'

          it_should 'set Z flag'
        end
      end
    end

    context 'CPX' do
      context 'immediate' do
        before { cpu.memory[0..1] = 0xE0, 0xA5 } # CPX #$A5

        it_should 'advance PC by two'

        it_should 'take two cycles'

        it_should 'compare and set flags', :x, 0xA5
      end

      context 'zero page' do
        before { cpu.memory[0..1] = 0xE4, 0xA5 } # CPX $A5

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'compare and set flags', :x, 0x33
      end

      context 'absolute' do
        before { cpu.memory[0..2] = 0xEC, 0x34, 0x12 } # CPX $1234

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'compare and set flags', :x, 0x99
      end
    end

    context 'CPY' do
      context 'immediate' do
        before { cpu.memory[0..1] = 0xC0, 0xA3 } # CPY #$A3

        it_should 'advance PC by two'

        it_should 'take two cycles'

        it_should 'compare and set flags', :y, 0xA3
      end

      context 'zero page' do
        before { cpu.memory[0..1] = 0xC4, 0xA3 } # CPY $A3

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'compare and set flags', :y, 0xF5
      end

      context 'absolute' do
        before { cpu.memory[0..2] = 0xCC, 0x44, 0x12 } # CPY $1234

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'compare and set flags', :y, 0xCC
      end
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

      it_should 'set X value', 0x06

      it_should 'reset Z flag'

      it_should 'reset N flag'

      context 'zero result' do
        before { cpu.x = 0x01 }

        it_should 'set Z flag'

        it_should 'reset N flag'
      end

      context 'negative result' do
        before { cpu.x = 0x00 }

        it_should 'set X value', 0xFF

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

      it_should 'set Y value', 0x06

      it_should 'reset Z flag'

      it_should 'reset N flag'

      context 'zero result' do
        before { cpu.y = 0x01 }

        it_should 'set Z flag'

        it_should 'reset N flag'
      end

      context 'negative result' do
        before { cpu.y = 0x00 }

        it_should 'set Y value', 0xFF

        it_should 'reset Z flag'

        it_should 'set N flag'
      end
    end

    context 'EOR' do
      pending 'not implemented'
    end

    context 'INC' do

      context 'zero page' do
        before { cpu.memory[0..1] = 0xE6, 0xA5 } # INC $A5

        it_should 'advance PC by two'

        it_should 'take five cycles'

        it_should 'set memory with value', 0xA5, 0x34
      end

      context 'zero page, x' do
        before do
          cpu.memory[0..1] = 0xF6, 0xA5 # INC $A5,X
          cpu.x = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take six cycles'

        it_should 'set memory with value', 0xB5, 0x67

        context 'wrapping around zero-page' do
          before { cpu.x = 0x60 }

          it_should 'set memory with value', 0x05, 0x12
        end
      end

      context 'absolute' do
        before do
          cpu.memory[0..2] = 0xEE, 0x34, 0x12 # INC $1234
        end

        it_should 'advance PC by three'

        it_should 'take six cycles'

        it_should 'set memory with value', 0x1234, 0x9A
      end

      context 'absolute, x' do
        before do
          cpu.memory[0..2] = 0xFE, 0x34, 0x12  # INC $1234,X
          cpu.x = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take seven cycles'

        it_should 'set memory with value', 0x1244, 0xCD

        it_should 'set N flag'

        context 'crossing page boundary' do
          before { cpu.x = 0xE1 }

          it_should 'set memory with value', 0x1315, 0x00

          it_should 'take seven cycles'

          it_should 'set Z flag'
        end

        context 'wrapping memory' do
          before { cpu.memory[0..2] = 0xFE, 0xF5, 0xFF } # INC $FFF5,X

          it_should 'set memory with value', 0x0005, 0x12
        end
      end
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
      before do
        cpu.pc = 0x02FF
        cpu.memory[0x02FF..0x0301] = 0x20, 0x34, 0x12 # 02FF: JSR $1234
        cpu.s = 0xF0
      end

      it_should 'take six cycles'

      it_should 'preserve flags'

      it_should 'set PC value', 0x1234

      it_should 'set S value', 0xEE

      it_should 'set memory with value', 0x01F0, 0x03

      it_should 'set memory with value', 0x01EF, 0x01
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

        context 'wrapping around zero-page' do
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

        context 'wrapping memory' do
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

        context 'wrapping memory' do
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

        context 'wrapping memory' do
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

        context 'wrapping around zero-page' do
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

        context 'wrapping around zero-page' do
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

        context 'wrapping memory' do
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

        context 'wrapping around zero-page' do
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

        context 'wrapping memory' do
          before { cpu.memory[0..2] = 0xBC, 0xF5, 0xFF } # LDY $FFF5,Y

          it_should 'set Y value', 0x11
        end
      end
    end

    context 'LSR' do
      context 'accumulator' do
        before do
          cpu.memory[0] = 0x4A # LSR A
          cpu.a = 0b11101110
        end

        it_should 'advance PC by one'

        it_should 'take two cycles'

        it_should 'set A value', 0b01110111

        it_should 'reset Z flag'

        it_should 'reset C flag'

        it_should 'reset N flag'

        context 'carry set' do
          before { cpu.c = true }

          it_should 'set A value', 0b01110111 # carry does not affect LSR
        end
      end

      context 'zero page' do
        before { cpu.memory[0..1] = 0x46, 0xA7 } # LSR $A7

        it_should 'advance PC by two'

        it_should 'take five cycles'

        it_should 'set memory with value', 0x00A7, 0x00

        it_should 'set C flag'

        it_should 'set Z flag'
      end

      context 'zero page, x' do
        before do
          cpu.memory[0..1] = 0x56, 0xA5  # LSR $A5,X
          cpu.x = 0x11
        end

        it_should 'advance PC by two'

        it_should 'take six cycles'

        it_should 'set memory with value', 0x00B6, 0x01

        it_should 'reset C flag'
      end

      context 'absolute' do
        before { cpu.memory[0..2] = 0x4E, 0x04, 0x13 } # LSR $1304

        it_should 'advance PC by three'

        it_should 'take six cycles'

        it_should 'set memory with value', 0x1304, 0x7F

        it_should 'set C flag'
      end

      context 'absolute, x' do
        before do
          cpu.memory[0..2] = 0x5E, 0x04, 0x13 # LSR $1304,X
          cpu.x = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take seven cycles'

        it_should 'set memory with value', 0x1314, 0x00

        it_should 'reset C flag'
      end
    end

    context 'NOP' do
      before { cpu.memory[0] = 0xEA }

      it_should 'advance PC by one'

      it_should 'take two cycles'

      it_should 'preserve flags'
    end

    context 'ORA' do
      pending 'not implemented'
    end

    context 'PHA' do
      before do
        cpu.memory[0] = 0x48
        cpu.a = 0xA5
        cpu.s = 0x7F
      end

      it_should 'advance PC by one'

      it_should 'take three cycles'

      it_should 'set memory with value', 0x017F, 0xA5

      it_should 'set S value', 0x7E

      it_should 'preserve flags'

      context 'wrap' do
        before { cpu.s = 0x00 }

        it_should 'set S value', 0xFF
      end
    end

    context 'PHP' do
      before do
        cpu.memory[0] = 0x08 # BRK
        cpu.s = 0xF0
      end

      it_should 'take three cycles'

      it_should 'advance PC by one'

      it_should 'set memory with P for various flag values', 0x01F0

      it_should 'preserve flags'
    end

    context 'PLA' do
      before do
        cpu.memory[0] = 0x68 # PLA
        cpu.s = 0x50
      end

      it_should 'advance PC by one'

      it_should 'take four cycles'

      it_should 'set A value', 0xB7

      it_should 'set S value', 0x51

      it_should 'reset Z flag'

      it_should 'set N flag'

      context 'wrap' do
        before { cpu.s = 0xFF }

        it_should 'set S value', 0x00
      end
    end

    context 'PLP' do
      before do
        cpu.memory[0] = 0x28 # PLP
        cpu.s = 0xA3
      end

      it_should 'advance PC by one'

      it_should 'take four cycles'

      it_should_behave_like 'read flags (P) from memory for various values', 0x01A4
    end

    context 'ROL' do
      before { cpu.c = false }

      context 'accumulator' do
        before do
          cpu.memory[0] = 0x2A # ROL A
          cpu.a = 0b11101110
          cpu.c = false
        end

        it_should 'advance PC by one'

        it_should 'take two cycles'

        it_should 'set A value', 0b11011100

        it_should 'reset Z flag'

        it_should 'set C flag'

        it_should 'set N flag'

        context 'with carry set' do
          before { cpu.c = true }

          it_should 'set A value', 0b11011101
        end
      end

      context 'zero page' do
        before { cpu.memory[0..1] = 0x26, 0xA7 } # ROL $A7

        it_should 'advance PC by two'

        it_should 'take five cycles'

        it_should 'set memory with value', 0x00A7, 0x02

        it_should 'reset N flag'

        it_should 'reset C flag'

        it_should 'reset Z flag'
      end

      context 'zero page, x' do
        before do
          cpu.memory[0..1] = 0x36, 0xA5  # ROL $A5,X
          cpu.x = 0x11
        end

        it_should 'advance PC by two'

        it_should 'take six cycles'

        it_should 'set memory with value', 0x00B6, 0x04

        it_should 'reset N flag'

        it_should 'reset C flag'

        it_should 'reset Z flag'
      end

      context 'absolute' do
        before { cpu.memory[0..2] = 0x2E, 0x04, 0x13 } # ROL $1304

        it_should 'advance PC by three'

        it_should 'take six cycles'

        it_should 'set memory with value', 0x1304, 0xFE

        it_should 'set N flag'

        it_should 'set C flag'

        it_should 'reset Z flag'
      end

      context 'absolute, x' do
        before do
          cpu.memory[0..2] = 0x3E, 0x04, 0x13 # ROL $1304,X
          cpu.x = 0x12
        end

        it_should 'advance PC by three'

        it_should 'take seven cycles'

        it_should 'set memory with value', 0x1316, 0x00

        it_should 'reset N flag'

        it_should 'set C flag'

        it_should 'set Z flag'
      end
    end

    context 'ROR' do
      before { cpu.c = false }

      context 'accumulator' do
        before do
          cpu.memory[0] = 0x6A # ROR A
          cpu.a = 0b11101110
        end

        it_should 'advance PC by one'

        it_should 'take two cycles'

        it_should 'set A value', 0b01110111

        it_should 'reset Z flag'

        it_should 'reset C flag'

        it_should 'reset N flag'

        context 'with carry set' do
          before { cpu.c = true }

          it_should 'set A value', 0b11110111
        end
      end

      context 'zero page' do
        before { cpu.memory[0..1] = 0x66, 0xA7 } # ROR $A7

        it_should 'advance PC by two'

        it_should 'take five cycles'

        it_should 'set memory with value', 0x00A7, 0x00

        it_should 'set C flag'

        it_should 'set Z flag'
      end

      context 'zero page, x' do
        before do
          cpu.memory[0..1] = 0x76, 0xA5  # ROR $A5,X
          cpu.x = 0x11
        end

        it_should 'advance PC by two'

        it_should 'take six cycles'

        it_should 'set memory with value', 0x00B6, 0x01

        it_should 'reset C flag'
      end

      context 'absolute' do
        before { cpu.memory[0..2] = 0x6E, 0x04, 0x13 } # ROR $1304

        it_should 'advance PC by three'

        it_should 'take six cycles'

        it_should 'set memory with value', 0x1304, 0x7F

        it_should 'set C flag'
      end

      context 'absolute, x' do
        before do
          cpu.memory[0..2] = 0x7E, 0x04, 0x13 # ROR $1304,X
          cpu.x = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take seven cycles'

        it_should 'set memory with value', 0x1314, 0x00

        it_should 'reset C flag'
      end
    end

    context 'RTI' do
      before do
        cpu.memory[0] = 0x40 # RTI
        cpu.memory[0x01EF..0x01F0] = 0x35, 0x12
        cpu.s = 0xED
      end

      it_should 'take six cycles'

      it_should 'set S value', 0xF0

      it_should 'set PC value', 0x1235

      it_should_behave_like 'read flags (P) from memory for various values', 0x01EE
    end

    context 'RTS' do
      before do
        cpu.memory[0] = 0x60 # RTS
        cpu.s = 0x5F
      end

      it_should 'take six cycles'

      it_should 'set PC value', 0x7800

      it_should 'preserve flags'
    end

    context 'SBC' do
      before do
        cpu.a = 0xAC
        cpu.c = true
        cpu.d = false
      end

      context 'immediate' do
        before { cpu.memory[0..1] = 0xE9, 0x22 } # SBC #$22

        it_should 'advance PC by two'

        it_should 'take two cycles'

        it_should 'set A value', 0x8A

        it_should 'reset Z flag'

        it_should 'set N flag'

        it_should 'set C flag'

        it_should 'reset V flag'

        context 'with carry' do
          before { cpu.c = false }

          it_should 'set A value', 0x89
        end

        # http://www.6502.org/tutorials/vflag.html
        context 'Bruce Clark paper tests' do
          it_should 'subtract and set A/C/V', 0x00, 0x01, 0xFF, false, false
          it_should 'subtract and set A/C/V', 0x80, 0x01, 0x7F, true,  true
          it_should 'subtract and set A/C/V', 0x7F, 0xFF, 0x80, false, true
        end

        context '2 - 10 = -8; no carry/overflow' do
          it_should 'subtract and set A/C/V', 0x02, 0x10, 0xF2, false, false
        end

        context 'decimal mode' do
          before { cpu.d = true }

          context 'result => 0' do
            before { cpu.a = 0x23 }

            it_should 'set A value', 1

            it_should 'set C flag'
          end

          context 'result < 0' do
            before { cpu.a = 0x21 }

            it_should 'set A value', 0x99

            it_should 'reset C flag'
          end
        end
      end

      context 'zero page' do
        before { cpu.memory[0..1] = 0xE5, 0xA4 } # SBC $A4

        it_should 'advance PC by two'

        it_should 'take three cycles'

        it_should 'set A value', 0xAD

        it_should 'set N flag'

        it_should 'reset C flag'

        it_should 'reset V flag'
      end

      context 'zero page, x' do
        before do
          cpu.memory[0..1] = 0xF5, 0xA5 # SBC $A5,X
          cpu.x = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take four cycles'

        it_should 'set A value', 0x46

        it_should 'set C flag'

        context 'wrapping zero-page boundary' do
          before { cpu.x = 0x62 }

          it_should 'set A value', 0x58

          it_should 'set C flag'
        end
      end

      context 'absolute' do
        before do
          cpu.memory[0..2] = 0xED, 0x34, 0x12 # SBC $1234
          cpu.n = false
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set A value', 0x13
      end

      context 'absolute, x' do
        before do
          cpu.memory[0..2] = 0xFD, 0x34, 0x12  # SBC $1234,X
          cpu.x = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set A value', 0xE0

        context 'crossing page boundary' do
          before { cpu.x = 0xD0 }

          it_should 'set A value', 0xAD

          it_should 'take five cycles'
        end

        context 'wrapping memory' do
          before { cpu.memory[0..2] = 0xFD, 0xF5, 0xFF } # SBC $FFF5,X

          it_should 'set A value', 0x9B
        end
      end

      context 'absolute, y' do
        before do
          cpu.memory[0..2] = 0xF9, 0x34, 0x12  # SBC $1234,Y
          cpu.y = 0x10
        end

        it_should 'advance PC by three'

        it_should 'take four cycles'

        it_should 'set A value', 0xE0

        context 'crossing page boundary' do
          before { cpu.y = 0xD0 }

          it_should 'set A value', 0xAD

          it_should 'take five cycles'
        end

        context 'wrapping memory' do
          before { cpu.memory[0..2] = 0xF9, 0xF5, 0xFF } # SBC $FFF5,Y

          it_should 'set A value', 0x9B
        end
      end

      context '(indirect, x)' do
        before do
          cpu.memory[0..1] = 0xE1, 0xA5  # SBC ($A5,X)
          cpu.x = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take six cycles'

        it_should 'set A value', 0x08

        context 'wrapping around zero-page' do
          before { cpu.x = 0x60 }

          it_should 'set A value', 0xF7
        end
      end

      context '(indirect), y' do
        before do
          cpu.memory[0..1] = 0xF1, 0xA5  # SBC ($A5),Y
          cpu.y = 0x10
        end

        it_should 'advance PC by two'

        it_should 'take five cycles'

        it_should 'set A value', 0x35

        context 'crossing page boundary' do
          before { cpu.y = 0xD0 }

          it_should 'set A value', 0x24

          it_should 'take six cycles'
        end

        context 'wrapping memory' do
          before { cpu.memory[0..1] = 0xF1, 0xA3}  # SBC ($A3),Y

          it_should 'set A value', 0x9B
        end
      end
    end

    context 'SEC' do
      before {
        cpu.memory[0] = 0x38 # SEC
        cpu.c = false
      }

      it_should 'set C flag'
    end

    context 'SED' do
      before {
        cpu.memory[0] = 0xF8 # SED
        cpu.d = false
      }

      it_should 'set D flag'
    end

    context 'SEI' do
      before {
        cpu.memory[0] = 0x78 # SEI
        cpu.i = false
      }

      it_should 'set I flag'
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

        context 'wrapping around zero-page' do
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

        context 'wrapping memory' do
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

        context 'wrapping memory' do
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

        context 'wrapping memory' do
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

        context 'wrapping around zero-page' do
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

        context 'wrapping around zero-page' do
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

        context 'wrapping around zero-page' do
          before { cpu.x = 0x60 }

          it_should 'set memory with value', 0x0005, 0x2F
        end
      end
    end

    context 'TAX' do
      before do
        cpu.memory[0] = 0xAA # TAX
        cpu.a = 0x45
      end

      it_should 'advance PC by one'

      it_should 'take two cycles'

      it_should 'set X value', 0x45

      it_should 'reset Z flag'

      it_should 'reset N flag'
    end

    context 'TAY' do
      before do
        cpu.memory[0] = 0xA8 # TAY
        cpu.a = 0xF5
      end

      it_should 'advance PC by one'

      it_should 'take two cycles'

      it_should 'set Y value', 0xF5

      it_should 'reset Z flag'

      it_should 'set N flag'
    end

    context 'TSX' do
      before do
        cpu.memory[0] = 0xBA # TSX
        cpu.s = 0xFC
      end

      it_should 'advance PC by one'

      it_should 'take two cycles'

      it_should 'set X value', 0xFC

      it_should 'reset Z flag'

      it_should 'set N flag'
    end

    context 'TXA' do
      before do
        cpu.memory[0] = 0x8A # TXA
        cpu.x = 0x00
      end

      it_should 'advance PC by one'

      it_should 'take two cycles'

      it_should 'set A value', 0x00

      it_should 'set Z flag'

      it_should 'reset N flag'
    end

    context 'TXS' do
      before do
        cpu.memory[0] = 0x9A # TXS
        cpu.x = 0xFF
      end

      it_should 'advance PC by one'

      it_should 'take two cycles'

      it_should 'set S value', 0xFF

      it_should 'preserve flags'
    end

    context 'TYA' do
      before do
        cpu.memory[0] = 0x98 # TYA
        cpu.y = 0xA0
      end

      it_should 'advance PC by one'

      it_should 'take two cycles'

      it_should 'set A value', 0xA0

      it_should 'reset Z flag'

      it_should 'set N flag'
    end

    # We don't deal with undocumented flags on BCD mode, maybe we should.
    # See http://www.6502.org/tutorials/vflag.html &
    #     http://atariage.com/forums/topic/163876-flags-on-decimal-mode-on-the-nmos-6502/
    # Stella/M6502 has this verison of the V code (M6502.ins, L271-305):
    #        @v = (~(@a ^ load) & (@a ^ t) & 0x80) != 0
    pending "undocumented flags on BCD mode"

    pending "nice CMP test: http://forum.6502.org/viewtopic.php?t=474#p2984"
  end
end
