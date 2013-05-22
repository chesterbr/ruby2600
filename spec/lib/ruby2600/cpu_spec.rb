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
      randomize :a, :x, :y, :n, :v, :i, :z, :c

      # Examples wil refer to these values. Add, but don't change!
      cpu.memory = []
      cpu.memory[0x0001] = 0xFE
      cpu.memory[0x0002] = 0xFF
      cpu.memory[0x0005] = 0x11
      cpu.memory[0x0006] = 0x03
      cpu.memory[0x0010] = 0x53
      cpu.memory[0x0011] = 0xA4
      cpu.memory[0x00A3] = 0xF5
      cpu.memory[0x00A4] = 0xFF
      cpu.memory[0x00A5] = 0x33
      cpu.memory[0x00A6] = 0x20
      cpu.memory[0x00B5] = 0x66
      cpu.memory[0x00B6] = 0x02
      cpu.memory[0x0266] = 0xA4
      cpu.memory[0x0311] = 0xB5
      cpu.memory[0x1122] = 0x07
      cpu.memory[0x1234] = 0x99
      cpu.memory[0x1235] = 0xAA
      cpu.memory[0x1244] = 0xCC
      cpu.memory[0x1304] = 0xFF
      cpu.memory[0x1314] = 0x00
      cpu.memory[0x1315] = 0xFF
      cpu.memory[0x2043] = 0x77
      cpu.memory[0x2103] = 0x88
    end

    def randomize(*attrs)
      attrs.each do |attr|
        value = attr =~ /[axy]/ ? rand(256) : [true, false].sample
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
      pending 'not implemented'
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

        context 'crossing zero-page boundary' do
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

        context 'crossing memory boundary' do
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

        context 'crossing memory boundary' do
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

        context 'crossing zero-page boundary' do
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

        context 'crossing memory boundary' do
          before { cpu.memory[0..1] = 0x31, 0xA3}  # AND ($A3),Y

          it_should 'set A value', 0x00
        end
      end
    end

    context 'ASL' do
      pending 'not implemented'
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
      pending 'not implemented'
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
      pending 'not implemented'
    end

    context 'CLI' do
      before {
        cpu.memory[0] = 0x58 # CLI
        cpu.i = true
      }

      it_should 'reset I flag'
    end

    context 'CLV' do
      pending 'not implemented'
    end

    context 'CMP' do
      pending 'not implemented'
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

        context 'crossing zero-page boundary' do
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

        context 'crossing memory boundary' do
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
      context 'accumulator' do
        before do
          cpu.memory[0] = 0x4A # LSR A
          cpu.a = 0b11101110
        end

        it_should 'advance PC by one'

        it_should 'take two cycles'

        it_should 'set A value', 0b01110111

        it_should 'reset C flag'
      end

      context 'zero page' do
        before { cpu.memory[0..1] = 0x46, 0xA5 } # LSR $A5

        it_should 'advance PC by two'

        it_should 'take five cycles'

        it_should 'set memory with value', 0x00A5, 0x19

        it_should 'set C flag'
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
      pending 'not implemented'
    end

    context 'PLA' do
      before do
        cpu.memory[0] = 0x68
        cpu.s = 0x50
        cpu.memory[0x0151] = 0xB7
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
      before {
        cpu.memory[0] = 0x38 # SEC
        cpu.c = false
      }

      it_should 'set C flag'
    end

    context 'SED' do
      pending 'not implemented'
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
      pending 'not implemented'
    end

    context 'TXA' do
      before do
        cpu.memory[0] = 0x8A # TXA
        cpu.x = 0x00
        cpu.a = 0x01 # FIXME remove when we pre-randomize registers
      end

      it_should 'advance PC by one'

      it_should 'take two cycles'

      it_should 'set A value', 0x00

      it_should 'set Z flag'

      it_should 'reset N flag'
    end

    context 'TXS' do
      pending 'not implemented'
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
  end
end
