module Ruby2600
  class CPU
    attr_accessor :memory
    attr_accessor :pc, :a, :x, :y, :s
    attr_accessor :n, :v, :b, :d, :i, :z, :c    # Flags (P register): nv-bdizc

    RESET_VECTOR = 0xFFFC

    OPCODE_SIZES = [
      0, 2, 0, 2, 2, 2, 2, 2, 1, 2, 1, 2, 3, 3, 3, 3,
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
      0, 6, 0, 8, 3, 3, 5, 5, 3, 2, 2, 2, 4, 4, 6, 6,
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

    # Instructions that have different opcodes for each access mode follow a bit pattern
    # represented on the tables below (see http://www.llx.com/~nparker/a2/opcodes.html)

    INSTRUCTION_GROUPS = [
      %w'xxx BIT JMP xxx STY LDY CPY CPX',
      %w'ORA AND EOR ADC STA LDA CMP SBC',
      %w'ASL ROL LSR ROR STX LDX DEC INC'
    ]

    ADDRESSING_MODE_GROUPS = [
      [ :immediate, :zero_page, nil, :absolute, nil, :zero_page_indexed_x, nil, :absolute_indexed_x ],
      [ :indexed_indirect_x, :zero_page, :immediate, :absolute, :indirect_indexed_y, :zero_page_indexed_x, :absolute_indexed_y, :absolute_indexed_x ],
      [ :immediate, :zero_page, :accumulator, :absolute, nil, :zero_page_indexed_x_or_y, nil, :absolute_indexed_x_or_y ]
    ]

    # Generate constants for instructions above for easy matching upon execution

    INSTRUCTION_GROUPS.each_with_index do |names, cc|
      names.each_with_index do |name, aaa|
        const_set name, (aaa << 5) + cc unless name == 'xxx'
      end
    end

    # Conditional branches (BPL, BMI, BVC, BVS, BCC, BCS, BNE, BEQ) also follow a bit
    # pattern for target flag and expected value, so we'll generalize them as "BXX"

    BXX = 0b00010000
    BRANCH_FLAGS = [:@n, :@v, :@c, :@z]

    # Some instructions take an extra cycle if memory access crosses a page boundary.
    # STA/STX/STY are notable exceptions, here is the reason: http://bit.ly/10JNkOR

    INSTRUCTIONS_WITH_PAGE_PENALTY = [ORA, AND, EOR, ADC, LDA, CMP, SBC, LDX, LDY]

    def initialize
      @pc = @x = @y = @a = @s = 0
    end

    def reset
      @pc = memory[RESET_VECTOR] + 0x100 * memory[RESET_VECTOR + 1]
    end

    def step
      fetch
      execute
    end

    private

    # Decodes instruction, parameter, addressing mode, opcode and next PC

    def fetch
      @opcode = memory[@pc] || 0

      if (@opcode & 0b00011111) == BXX
        @instruction = BXX
      else
        @instruction_group  = (@opcode & 0b00000011)
        mode_in_group       = (@opcode & 0b00011100) >> 2
        @addressing_mode = ADDRESSING_MODE_GROUPS[@instruction_group][mode_in_group]
        @instruction = (@opcode & 0b11100011)
      end

      @param_lo = memory[word(@pc + 1)] || 0
      @param_hi = memory[word(@pc + 2)] || 0
      @param    = @param_hi * 0x100 + @param_lo

      @branch_cost = 0

      @pc = word(@pc + OPCODE_SIZES[@opcode])
    end

    # These helpers allow us to "mark" most operations
    # with the flags that should reflect their values

    def flag_nz(value)
      @z = (value == 0)
      @n = (value & 0b10000000 != 0)
    end

    def flag_nzc(value)
      flag_nz value
      @c = value >= 0
    end

    # Core execution (try individual opcodes first, then instructions)

    def execute
      execute_instruction unless execute_opcode
      time_in_cycles
    end

    def execute_opcode
      case @opcode
      when 0xEA # NOP
      when 0xE8 # INX
        flag_nz @x = byte(@x + 1)
      when 0xC8 # INY
        flag_nz @y = byte(@y + 1)
      when 0xCA # DEX
        flag_nz @x = byte(@x - 1)
      when 0x88 # DEY
        flag_nz @y = byte(@y - 1)
      when 0x4C # JMP
        @pc = @param
      when 0x6C # JMP()
        @pc = 0x100 * memory[@param + 1] + memory[@param]
      when 0xAA # TAX
        flag_nz @x = @a
      when 0xA8 # TAY
        flag_nz @y = @a
      when 0x8A # TXA
        flag_nz @a = @x
      when 0x98 # TYA
        flag_nz @a = @y
      when 0xBA # TSX
        flag_nz @x = @s
      when 0x9A # TXS
        @s = @x
      when 0x18 # CLC
        @c = false
      when 0x38 # SEC
        @c = true
      when 0xD8 # CLD
        @d = false
      when 0xF8 # SED
        @d = true
      when 0x58 # CLI
        @i = false
      when 0x78 # SEI
        @i = true
      when 0x48 # PHA
        push @a
      when 0x68 # PLA
        flag_nz @a = pop
      when 0x20 # JSR
        push_word @pc - 1
        @pc = @param
      when 0x60 # RTS
        @pc = word(pop_word + 1)
      else
        return false
      end
      true
    end

    def execute_instruction
      case @instruction
      when AND
        flag_nz @a = @a & load
      when BIT
        flag_nz (@a & load)
        @v = @a[6] & load[6] != 0
      when LDA
        flag_nz @a = load
      when LDX
        flag_nz @x = load
      when LDY
        flag_nz @y = load
      when INC
        flag_nz store byte(load + 1)
      when ADC, SBC
        flag_nz @a = arithmetic
      when STA
        store @a
      when STX
        store @x
      when STY
        store @y
      when ASL
        _ = load
        @c = _[7].nonzero?
        flag_nz store byte(_ << 1)
      when LSR
        _ = load
        @c = _[0].nonzero?
        flag_nz store _ >> 1
      when CPX
        # FIXME not sure if this is dealing with signed
        flag_nzc @x - load
      when CPY
        # FIXME not sure if this is dealing with signed
        flag_nzc @y - load
      when BXX
        @pc = branch
      end
    end

    # Generalized instructions (branches, arithmetic)

    def branch
      return @pc unless should_branch?
      new_pc = word(@pc + numeric_value(@param_lo))
      @branch_cost = (@pc & 0xFF00) == (new_pc & 0xFF00) ? 1 : 2
      new_pc
    end

    def should_branch?
      flag     = (@opcode & 0b11000000) >> 6
      expected = (@opcode & 0b00100000) != 0
      actual   = instance_variable_get(BRANCH_FLAGS[flag])
      !(expected ^ actual)
    end

    def arithmetic
      signal = @instruction == ADC ? 1 : -1
      carry  = @instruction == ADC ? bit(@c) : bit(@c) - 1
      limit  = @instruction == ADC ? bcd(255) : -1

      k = numeric_value(@a) + signal * numeric_value(load) + carry
      t = bcd(@a) + signal * bcd(load) + carry
      @v = k > 127 || k < -128
      @c = t > limit
      value_to_bcd(t) & 0xFF
    end

    # Read/write memory/A for (most) addressing modes. load and save
    # load and save can be prefixed with flag_* to update P flags

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
      (@param_lo + @x) % 0x100
    end

    def zero_page_indexed_y
      (@param_lo + @y) % 0x100
    end

    def zero_page_indexed_x_or_y
      [LDX, STX].include?(@instruction) ? zero_page_indexed_y : zero_page_indexed_x
    end

    def absolute
      @param
    end

    def absolute_indexed_x
      (@param + @x) % 0x10000
    end

    def absolute_indexed_y
      (@param + @y) % 0x10000
    end

    def absolute_indexed_x_or_y
      [LDX, STX].include?(@instruction) ? absolute_indexed_y : absolute_indexed_x
    end

    def indirect_indexed_y
      (memory[@param_lo + 1] * 0x100 + memory[@param_lo] + @y) % 0x10000
    end

    def indexed_indirect_x
      indexed_param = (@param_lo + @x) % 0x100
      memory[indexed_param + 1] * 0x100 + memory[indexed_param]
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

    # Timing

    def time_in_cycles
      cycles = OPCODE_CYCLE_COUNTS[@opcode] + @branch_cost
      cycles += 1 if penalize_for_page_boundary_cross?
      cycles
    end

    def penalize_for_page_boundary_cross?
      return false unless INSTRUCTIONS_WITH_PAGE_PENALTY.include? @instruction
      delta = case @addressing_mode
              when :absolute_indexed_y then @param_lo + @y
              when :indirect_indexed_y then memory[@param_lo] + @y
              when :absolute_indexed_x then @param_lo + @x
              when :absolute_indexed_x_or_y then @param_lo + (@instruction == LDX ? @y : @x)
              else 0
              end
      delta > 0xFF
    end

    # Two's complement conversion for byte values

    def numeric_value(signed_byte)
      signed_byte > 0x7F ? signed_byte - 0x100 : signed_byte
    end

    def signed_byte(numeric_value)
      numeric_value < 0 ? 0x100 + numeric_value  : numeric_value
    end

    # BCD function will only convert if decimal mode. It will also
    # conveniently convert 0xFF to 99 (for easy c flag setting on ADC)

    def bcd(value)
      return value unless @d
      ([value / 16, 9].min) * 10 + ([value % 16, 9].min)
    end

    def value_to_bcd(value)
      return value unless @d
      value = 100 + value if value < 0
      value -= 100        if value > 99
      (value / 10) * 16 + (value % 10)
    end

    # Keeping values within their bit sizes (due to lack of byte/word types)

    def byte(value)
      (value || 0) & 0xFF
    end

    def word(value)
      (value || 0) & 0xFFFF
    end

    def bit(flag)
      flag ? 1 : 0
    end

    # Debug tools

    def to_s
      "PC=#{sprintf("$%04X", @pc)} A=#{sprintf("$%02X", @a)} X=#{sprintf("$%02X", @x)} Y=#{sprintf("$%02X", @y)}"
    end
  end
end
