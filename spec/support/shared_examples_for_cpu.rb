CPU_8_BIT_REGISTERS = %w'a x y s'
CPU_FLAGS = %w'n v d i z c'

CPU_8_BIT_REGISTERS.each do |register|
  shared_examples_for "set #{register.upcase} value" do |expected|
    it do
      cpu.step

      value = cpu.send(register)
      expect(value).to be(expected), "Expected: #{hex_byte(expected)}, found: #{hex_byte(value)}"
    end
  end
end

CPU_FLAGS.each do |flag|
  shared_examples_for "set #{flag.upcase} flag" do
    it do
      cpu.step

      expect(cpu.send(flag)).to be_truthy
    end
  end

  shared_examples_for "reset #{flag.upcase} flag" do
    it do
      cpu.step

      expect(cpu.send(flag)).to be_falsey
    end
  end
end

shared_examples_for "preserve flags" do
  CPU_FLAGS.each do |flag|
    it "keeps #{flag} reset" do
      cpu.send("#{flag}=", false)

      cpu.step

      expect(cpu.send(flag)).to be_falsey
    end

    it "keeps #{flag} set" do
      cpu.send("#{flag}=", true)

      cpu.step

      expect(cpu.send(flag)).to be_truthy
    end
  end
end

shared_examples_for 'set PC value' do |expected|
  it do
    cpu.step

    value = cpu.pc
    expect(value).to be(expected), "Expected: #{hex_word(expected)}, found: #{hex_word(value)}"
  end
end

shared_examples_for 'set memory with value' do |position, expected|
  it do
    cpu.step

    value = cpu.memory[position]
    expect(value).to be(expected), "Expected: #{hex_byte(expected)} at address #{hex_word(position)}, found: #{hex_byte(value)} (#{value.inspect})"
  end
end

humanized = %w{zero one two three four five six seven}

1.upto 3 do |number|
  shared_examples_for "advance PC by #{humanized[number]}" do
    it { expect { cpu.step }.to change { cpu.pc }.by number }
  end
end

2.upto 7 do |number|
  shared_examples_for "take #{humanized[number]} cycles" do
    it { expect(cpu.step).to eq(number) }
  end
end

shared_examples_for 'add and set A/C/V' do |a, m, result, c, v|
  before do
    cpu.c = false              # CLC
    cpu.a = a                  # LDA #$a
    cpu.memory[0..1] = 0x69, m # ADC #$m
    cpu.step
  end

  it { expect(cpu.a).to eq(result) }
  it { expect(cpu.c).to eq(c) }
  it { expect(cpu.v).to eq(v) }
end

shared_examples_for 'subtract and set A/C/V' do |a, m, result, c, v|
  before do
    cpu.c = true               # SEC
    cpu.a = a                  # LDA #$a
    cpu.memory[0..1] = 0xE9, m # SBC #$m
    cpu.step
  end

  it { expect(cpu.a).to eq(result) }
  it { expect(cpu.c).to eq(c) }
  it { expect(cpu.v).to eq(v) }
end

shared_examples_for 'set memory with P for various flag values' do |address|
  context 'all flags set' do
    before { cpu.n = cpu.v = cpu.d = cpu.i = cpu.z = cpu.c = true }

    it_should 'set memory with value', address, 0b11111111
  end

  context 'all flags clear' do
    before { cpu.n = cpu.v = cpu.d = cpu.i = cpu.z = cpu.c = false }

    it_should 'set memory with value', address, 0b00110000
  end

  context 'mixed flags' do
    before do
      cpu.n = cpu.d = cpu.z = true
      cpu.v = cpu.i = cpu.c = false
    end

    it_should 'set memory with value', address, 0b10111010
  end
end

shared_examples_for 'read flags (P) from memory for various values' do |address|
  context 'all flags set' do
    before { cpu.memory[address] = 0b11111111 }

    it_should 'set N flag'
    it_should 'set V flag'
    it_should 'set D flag'
    it_should 'set I flag'
    it_should 'set Z flag'
    it_should 'set C flag'
  end

  context 'all flags clear' do
    before { cpu.memory[address] = 0 }

    it_should 'reset N flag'
    it_should 'reset V flag'
    it_should 'reset D flag'
    it_should 'reset I flag'
    it_should 'reset Z flag'
    it_should 'reset C flag'
  end

  context 'mixed flags' do
    before { cpu.memory[address] = 0b10111010 }

    it_should 'set N flag'
    it_should 'set D flag'
    it_should 'set Z flag'

    it_should 'reset V flag'
    it_should 'reset I flag'
    it_should 'reset C flag'
  end
end

shared_examples_for "a branch instruction" do
  before { cpu.pc = 0x0510 }

  context 'no branch' do
    before do
      cpu.memory[0x0510..0x0511] = opcode, 0x02  # B?? $0514
      cpu.send("#{flag}=", !branch_state)
    end

    it_should 'take two cycles'

    it_should 'advance PC by two'

    it_should 'preserve flags'
  end

  context 'branch' do
    before { cpu.send("#{flag}=", branch_state) }

    context 'forward on same page' do
      before { cpu.memory[0x0510..0x0511] = opcode, 0x02 }  # B?? $0514

      it_should 'take three cycles'

      it_should 'set PC value', 0x0514

      it_should 'preserve flags'
    end

    context 'backward on same page' do
      before { cpu.memory[0x0510..0x0511] = opcode, 0xFC }  # B?? $050E

      it_should 'take three cycles'

      it_should 'set PC value', 0x050E

      it_should 'preserve flags'
    end

    context 'forward on another page' do
      before do
        cpu.pc = 0x0590
        cpu.memory[0x0590..0x0591] = opcode, 0x7F # B?? $0611
      end

      it_should 'take four cycles'

      it_should 'set PC value', 0x0611

      it_should 'preserve flags'
    end

    context 'backward on another page' do
      before { cpu.memory[0x0510..0x0511] = opcode, 0x80 }  # B?? $0492

      it_should 'take four cycles'

      it_should 'set PC value', 0x0492

      it_should 'preserve flags'
    end

    context 'forward wrapping around memory' do
      before do
        cpu.pc = 0xFF90
        cpu.memory[0xFF90..0xFF91] = opcode, 0x7F # B?? $0611
      end

      it_should 'take four cycles'

      it_should 'set PC value', 0x0011

      it_should 'preserve flags'
    end
  end
end

shared_examples_for 'compare and set flags' do |register, value|
  context 'register < value' do
    before { cpu.send("#{register}=", value - 1) }

    it_should 'set N flag'

    it_should 'reset C flag'

    it_should 'reset Z flag'
  end

  context 'register = value' do
    before { cpu.send("#{register}=", value) }

    it_should 'reset N flag'

    it_should 'set C flag'

    it_should 'set Z flag'
  end

  context 'register > value' do
    before { cpu.send("#{register}=", value + 1) }

    it_should 'reset N flag'

    it_should 'set C flag'

    it_should 'reset Z flag'
  end
end

shared_examples_for 'work on any memory position' do
  it 'works on lower 1KB' do
    0x1000.downto 0x0000 do |position|
      step_and_check(code, position)
    end
  end

  it 'works on 2600 cart region' do |position|
    0xFFFF.downto 0xF000 do |position|
      step_and_check(code, position)
    end
  end

  def step_and_check(code, position)
    store_in_64KB_memory code, position
    expected_pc = position + code.size & 0xFFFF
    randomize :a

    cpu.pc = position
    cpu.step

    expect(cpu.pc).to eq(expected_pc)
    expect(cpu.a).to  eq(expected_a), "for position=#{hex_word(position)}" if expected_a
  end

  def store_in_64KB_memory(code, position)
    code.each do |byte|
      cpu.memory[position] = byte
      position = (position + 1) & 0xFFFF
    end
  end

end
