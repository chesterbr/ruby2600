module Ruby2600
  class CPU
    attr_accessor :memory
    attr_accessor :pc, :a, :x, :y, :s
    attr_accessor :n, :v, :d, :i, :z, :c  # Flags (P register): nv--dizc
    attr_accessor :halted                 # Simulates RDY (if true, clock is ignored)

    RESET_VECTOR = 0xFFFC
    BRK_VECTOR   = 0xFFFE

    OPCODE_SIZES = [
      1, 2, 0, 2, 2, 2, 2, 2, 1, 2, 1, 2, 3, 3, 3, 3,
      2, 2, 0, 2, 2, 2, 2, 2, 1, 3, 1, 3, 3, 3, 3, 3,
      3, 2, 0, 2, 2, 2, 2, 2, 1, 2, 1, 2, 3, 3, 3, 3,
      2, 2, 0, 2, 2, 2, 2, 2, 1, 3, 1, 3, 3, 3, 3, 3,
      0, 2, 0, 2, 2, 2, 2, 2, 1, 2, 1, 2, 0, 3, 3, 3,
      2, 2, 0, 2, 2, 2, 2, 2, 1, 3, 1, 3, 3, 3, 3, 3,
      0, 2, 0, 2, 2, 2, 2, 2, 1, 2, 1, 2, 0, 3, 3, 3,
      2, 2, 0, 2, 2, 2, 2, 2, 1, 3, 1, 3, 3, 3, 3, 3,
      2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 1, 2, 3, 3, 3, 3,
      2, 2, 0, 2, 2, 2, 2, 2, 1, 3, 1, 0, 3, 3, 3, 3,
      2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 1, 2, 3, 3, 3, 3,
      2, 2, 0, 2, 2, 2, 2, 2, 1, 3, 1, 3, 3, 3, 3, 3,
      2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 1, 2, 3, 3, 3, 3,
      2, 2, 0, 2, 2, 2, 2, 2, 1, 3, 1, 3, 3, 3, 3, 3,
      2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 1, 2, 3, 3, 3, 3,
      2, 2, 0, 2, 2, 2, 2, 2, 1, 3, 1, 3, 3, 3, 3, 3
    ]

    OPCODE_CYCLE_COUNTS = [
      7, 6, 0, 8, 3, 3, 5, 5, 3, 2, 2, 2, 4, 4, 6, 6,
      2, 5, 0, 8, 4, 4, 6, 6, 2, 4, 2, 7, 4, 4, 7, 7,
      6, 6, 0, 8, 3, 3, 5, 5, 4, 2, 2, 2, 4, 4, 6, 6,
      2, 5, 0, 8, 4, 4, 6, 6, 2, 4, 2, 7, 4, 4, 7, 7,
      6, 6, 0, 8, 3, 3, 5, 5, 3, 2, 2, 2, 3, 4, 6, 6,
      2, 5, 0, 8, 4, 4, 6, 6, 2, 4, 2, 7, 4, 4, 7, 7,
      6, 6, 0, 8, 3, 3, 5, 5, 4, 2, 2, 2, 5, 4, 6, 6,
      2, 5, 0, 8, 4, 4, 6, 6, 2, 4, 2, 7, 4, 4, 7, 7,
      2, 6, 2, 6, 3, 3, 3, 3, 2, 2, 2, 2, 4, 4, 4, 4,
      2, 6, 0, 6, 4, 4, 4, 4, 2, 5, 2, 5, 5, 5, 5, 5,
      2, 6, 2, 6, 3, 3, 3, 3, 2, 2, 2, 2, 4, 4, 4, 4,
      2, 5, 0, 5, 4, 4, 4, 4, 2, 4, 2, 4, 4, 4, 4, 4,
      2, 6, 2, 8, 3, 3, 5, 5, 2, 2, 2, 2, 4, 4, 6, 6,
      2, 5, 0, 8, 4, 4, 6, 6, 2, 4, 2, 7, 4, 4, 7, 7,
      2, 6, 2, 8, 3, 3, 5, 5, 2, 2, 2, 2, 4, 4, 6, 6,
      2, 5, 0, 8, 4, 4, 6, 6, 2, 4, 2, 7, 4, 4, 7, 7
    ]

    # The 6507 recognizes 151 different opcodes. These have implicit addressing,
    # (that is, map to a single logical instruction) and can be decoded directly:

    BRK = 0x00; PHP = 0x08; JSR = 0x20; PLP = 0x28; RTI = 0x40;
    PHA = 0x48; RTS = 0x60; PLA = 0x68; DEY = 0x88; TXA = 0x8A;
    TYA = 0x98; TXS = 0x9A; TAY = 0xA8; TAX = 0xAA; CLV = 0xB8;
    TSX = 0xBA; INY = 0xC8; DEX = 0xCA; INX = 0xE8; NOP = 0xEA

    # The remaining logical instructions map to different opcodes, depending on
    # the type of parameter they will be taking (a memory address, a value, etc.)
    #
    # We'll use info from from http://www.llx.com/~nparker/a2/opcodes.html) to build
    # bitmask constants that will ease decoding the opcodes into instructions:

    ADDRESSING_MODE_GROUPS = [
      [ :immediate, :zero_page, nil, :absolute, nil, :zero_page_indexed_x, nil, :absolute_indexed_x ],
      [ :indexed_indirect_x, :zero_page, :immediate, :absolute, :indirect_indexed_y, :zero_page_indexed_x, :absolute_indexed_y, :absolute_indexed_x ],
      [ :immediate, :zero_page, :accumulator, :absolute, nil, :zero_page_indexed_x_or_y, nil, :absolute_indexed_x_or_y ]
    ]

    INSTRUCTION_GROUPS = [
      %w'xxx BIT JMP JMPabs STY LDY CPY CPX',
      %w'ORA AND EOR ADC    STA LDA CMP SBC',
      %w'ASL ROL LSR ROR    STX LDX DEC INC'
    ]

    INSTRUCTION_GROUPS.each_with_index do |names, cc|
      names.each_with_index do |name, aaa|
        const_set name, (aaa << 5) + cc unless name == 'xxx'
      end
    end

    # Conditional branches (BPL, BMI, BVC, BVS, BCC, BCS, BNE, BEQ) and the symmetric
    # set/clear flag instructions (SEC, SEI, SED, CLD, CLI, CLD) also follow bit
    # patterns (for target flag and expected/set value) and will be generalized
    # as "BXX" and SCX":

    BXX = 0b00010000
    SCX = 0b00011000
    BXX_FLAGS = [:@n, :@v, :@c, :@z]
    SCX_FLAGS = [:@c, :@i, :@v, :@d] # @v not (officially) used

    # Instructions that index (non-zero-page) memory have a 1-cycle penality if
    # the resulting address crosses page boundaries (trivia: it is, in fact, an
    # optimization of the non-crossing cases: http://bit.ly/10JNkOR)

    INSTRUCTIONS_WITH_PAGE_PENALTY = [ORA, AND, EOR, ADC, LDA, CMP, SBC, LDX, LDY]

    def initialize
      @pc = @x = @y = @a = @s = 0
    end

    def reset
      @pc = memory_word(RESET_VECTOR)
    end

    def step
      fetch
      decode
      execute
      @time_in_cycles
    end

    def tick
      return if @halted
      if !@time_in_cycles
        fetch
        decode
      end
      @time_in_cycles -= 1
      if @time_in_cycles == 0
        execute
        @time_in_cycles = nil
      end
    end

    private

    # 6507 has an internal "T-state" that gets incremented as each clock cycle
    # advances within an instruction (cf. http://www.pagetable.com/?p=39).
    #
    # For simplicity, let's stick to the fetch-decode-execute cycle and advance
    # the PC to the next instruction right on fetch. As a consequence, "@pc" will
    # be the PC for *NEXT* instruction throughout the decode and execute phases.

    def fetch
      @opcode   = memory[@pc] || 0
      @param_lo = memory[word(@pc + 1)] || 0
      @param_hi = memory[word(@pc + 2)] || 0
      @param    = @param_hi * 0x100 + @param_lo
      @pc       = word(@pc + OPCODE_SIZES[@opcode])
    end

    def decode
      if    (@opcode & 0b00011111) == BXX
        @instruction = BXX
      elsif (@opcode & 0b00011111) == SCX
        @instruction = SCX
      else
        @instruction_group  = (@opcode & 0b00000011)
        mode_in_group       = (@opcode & 0b00011100) >> 2
        @addressing_mode = ADDRESSING_MODE_GROUPS[@instruction_group][mode_in_group]
        @instruction = (@opcode & 0b11100011)
      end

      @time_in_cycles = time_in_cycles
    end

    # These helpers allow us to "tag" operations with affected flags

    def flag_nz(value)
      @z = value.zero?
      @n = value[7] != 0
    end

    def flag_nzc(value)
      flag_nz value
      @c = value >= 0
    end

    # Core execution logic

    def execute
      case @opcode
      when NOP
      when INX
        flag_nz @x = byte(@x + 1)
      when INY
        flag_nz @y = byte(@y + 1)
      when DEX
        flag_nz @x = byte(@x - 1)
      when DEY
        flag_nz @y = byte(@y - 1)
      when TAX
        flag_nz @x = @a
      when TAY
        flag_nz @y = @a
      when TXA
        flag_nz @a = @x
      when TYA
        flag_nz @a = @y
      when TSX
        flag_nz @x = @s
      when TXS
        @s = @x
      when CLV
        @v = false
      when PHP
        push p
      when PLP
        self.p = pop
      when PHA
        push @a
      when PLA
        flag_nz @a = pop
      when JSR
        push_word @pc - 1
        @pc = @param
      when RTS
        @pc = word(pop_word + 1)
      when BRK
        push_word @pc
        push p
        @i = true
        @pc = memory_word(BRK_VECTOR)
      when RTI
        self.p = pop
        @pc = pop_word
      else
        # Not an implicit addressing instruction
        execute_with_addressing_mode
      end
    end

    def execute_with_addressing_mode
      case @instruction
      when AND
        flag_nz @a = @a & load
      when ORA
        flag_nz @a = @a | load
      when EOR
        flag_nz @a = @a ^ load
      when BIT
        @z = (@a & load).zero?
        @v = load[6] != 0
        @n = load[7] != 0
      when LDA
        flag_nz @a = load
      when LDX
        flag_nz @x = load
      when LDY
        flag_nz @y = load
      when INC
        flag_nz store byte(load + 1)
      when DEC
        flag_nz store byte(load - 1)
      when ADC, SBC
        flag_nz @a = arithmetic
      when STA
        store @a
      when STX
        store @x
      when STY
        store @y
      when ASL, ROL, LSR, ROR
        flag_nz store shift
      when CMP
        flag_nzc @a - load
      when CPX
        flag_nzc @x - load
      when CPY
        flag_nzc @y - load
      when JMP
        @pc = @param
      when JMPabs
        @pc = memory_word(@param)
      when BXX
        @pc = branch
      when SCX
        instance_variable_set SCX_FLAGS[@opcode >> 6], @opcode[5] == 1
      end
    end

    # Generalized instructions (branches, arithmetic, shift)

    def branch
      should_branch? ? branch_target_address : @pc
    end

    def branch_target_address
      return word(@pc + signed(@param_lo))
    end

    def should_branch?
      flag     = (@opcode & 0b11000000) >> 6
      expected = (@opcode & 0b00100000) != 0
      actual   = instance_variable_get(BXX_FLAGS[flag])
      !(expected ^ actual)
    end

    def arithmetic
      signal = @instruction == ADC ? 1 : -1
      carry  = @instruction == ADC ? bit(@c) : bit(@c) - 1
      limit  = @instruction == ADC ? bcd_to_value(255) : -1

      k = signed(@a) + signal * signed(load) + carry
      t = bcd_to_value(@a) + signal * bcd_to_value(load) + carry
      @v = k > 127 || k < -128
      @c = t > limit
      value_to_bcd(t) & 0xFF
    end

    def shift
      right  = @instruction & 0b01000000 != 0
      rotate = @instruction & 0b00100000 != 0

      new_bit = rotate ? (bit(@c) << (right ? 7 : 0)) : 0
      delta   = right  ? -1 : 1

      _ = load
      @c = _[right ? 0 : 7] == 1
      byte(_ << delta) | new_bit
    end

    # Memory (and A) read/write for the current opcode's access mode.
    # store() returns the written value, allowing it to be prefixed with flag_*

    def load
      case @addressing_mode
      when :immediate   then @param_lo
      when :accumulator then @a
      else              memory[self.send(@addressing_mode)] || 0
      end
    end

    def store(value)
      case @addressing_mode
      when :immediate   then memory[@param_lo] = value
      when :accumulator then @a = value
      else              memory[self.send(@addressing_mode)] = value
      end
      value
    end

    def zero_page
      @param_lo
    end

    def zero_page_indexed_x
      byte @param_lo + @x
    end

    def zero_page_indexed_y
      byte @param_lo + @y
    end

    def zero_page_indexed_x_or_y
      [LDX, STX].include?(@instruction) ? zero_page_indexed_y : zero_page_indexed_x
    end

    def absolute
      @param
    end

    def absolute_indexed_x
      word @param + @x
    end

    def absolute_indexed_y
      word @param + @y
    end

    def absolute_indexed_x_or_y
      [LDX, STX].include?(@instruction) ? absolute_indexed_y : absolute_indexed_x
    end

    def indirect_indexed_y
      word(memory_word(@param_lo) + @y)
    end

    def indexed_indirect_x
      memory_word(byte(@param_lo + @x))
    end

    # Stack

    def push(value)
      memory[0x100 + @s] = value
      @s = byte(@s - 1)
    end

    def pop
      @s = byte(@s + 1)
      memory[0x100 + @s]
    end

    def push_word(value)
      push value / 0x0100
      push byte(value)
    end

    def pop_word
      pop + (0x100 * pop)
    end

    # Flags are stored as individual booleans, but sometimes we need
    # them as a flags register (P), which bit-maps to "NV_BDIZC"
    #
    # Notice that bit 5 (_) is always 1 and bit 4 (B) is only false
    # on non-software interrupts (IRQ/NMI), which we don't support.

    def p
      _  = 0b00110000
      _ += 0b10000000 if @n
      _ += 0b01000000 if @v
      _ += 0b00001000 if @d
      _ += 0b00000100 if @i
      _ += 0b00000010 if @z
      _ += 0b00000001 if @c
      _
    end

    def p=(value)
      @n = (value & 0b10000000) != 0
      @v = (value & 0b01000000) != 0
      @d = (value & 0b00001000) != 0
      @i = (value & 0b00000100) != 0
      @z = (value & 0b00000010) != 0
      @c = (value & 0b00000001) != 0
    end

    # Timing

    def time_in_cycles
      cycles = OPCODE_CYCLE_COUNTS[@opcode]
      cycles += 1 if penalize_for_page_boundary_cross?
      cycles += branch_cost
    end

    def penalize_for_page_boundary_cross?
      return false unless INSTRUCTIONS_WITH_PAGE_PENALTY.include? @instruction
      lo_addr = case @addressing_mode
                when :absolute_indexed_y then @param_lo + @y
                when :indirect_indexed_y then memory[@param_lo] + @y
                when :absolute_indexed_x then @param_lo + @x
                when :absolute_indexed_x_or_y then @param_lo + (@instruction == LDX ? @y : @x)
                else 0
                end
      lo_addr > 0xFF
    end

    def branch_cost
      return 0 unless @instruction == BXX && should_branch?
      (@pc & 0xFF00) == (branch_target_address & 0xFF00) ? 1 : 2
    end

    # BCD functions are inert unless we are in decimal mode. bcd will also
    # conveniently make 0xFF into 99, making carry-check decimal-mode-agnostic

    def bcd_to_value(value)
      return value unless @d
      ([value / 16, 9].min) * 10 + ([value % 16, 9].min)
    end

    def value_to_bcd(value)
      return value unless @d
      value = 100 + value if value < 0
      value -= 100        if value > 99
      (value / 10) * 16 + (value % 10)
    end

    # Convenience conversions (most due to the lack of byte/word & signed/unsigned types)

    def byte(value)
      (value || 0) & 0xFF
    end

    def word(value)
      (value || 0) & 0xFFFF
    end

    def bit(flag)
      flag ? 1 : 0
    end

    def signed(signed_byte)
      signed_byte > 0x7F ? signed_byte - 0x100 : signed_byte
    end

    def memory_word(address)
      memory[word(address + 1)] * 0x100 + memory[address]
    end

    # Debug tools (should be expanded and moved into its own module)

    def to_s
      "PC=#{sprintf("$%04X", @pc)} A=#{sprintf("$%02X", @a)} X=#{sprintf("$%02X", @x)} Y=#{sprintf("$%02X", @y)}"
    end
  end
end
