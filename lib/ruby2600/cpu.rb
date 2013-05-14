module Ruby2600
  class CPU
    attr_accessor :memory
    attr_accessor :pc, :a, :x, :y
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
      2, 2, 0, 2, 2, 2, 2, 2, 1, 3, 0, 0, 3, 3, 3, 3,
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

    # Opcodes that map to the same mnemonic instruction (in different access
    # modes) have bit patterns (http://www.llx.com/~nparker/a2/opcodes.html)
    # used by the constants below to simplify identification

    INSTRUCTION_GROUPS = [
      %w'xxx BIT JMP xxx STY LDY CPY CPX',
      %w'ORA AND EOR ADC STA LDA CMP SBC',
      %w'ASL ROL LSR ROR STX LDX DEC INC'
    ]

    INSTRUCTION_GROUPS.each_with_index do |names, cc|
      names.each_with_index do |name, aaa|
        const_set name, (aaa << 5) + cc unless name == 'xxx'
      end
    end

    ADDRESSING_MODE_GROUPS = [
      [ :immediate, :zero_page, nil, :absolute, nil, :zero_page_indexed_x, nil, :absolute_indexed_x ],
      [ :indexed_indirect_x, :zero_page, :immediate, :absolute, :indirect_indexed_y, :zero_page_indexed_x, :absolute_indexed_y, :absolute_indexed_x ],
      [ :immediate, :zero_page, :accumulator, :absolute, nil, :zero_page_indexed_x_or_y, nil, :absolute_indexed_x_or_y ]
    ]

    # Conditional branches also follow a pattern (which tells what flag should have
    # which value in order to trigger the branch). We'll treat them all as "BXX"

    BXX = 0b00010000
    BRANCH_FLAGS = [:@n, :@v, :@c, :@z]

    def initialize
      @pc = @x = @y = @a = 0
    end

    def reset
      @pc = memory[RESET_VECTOR] + 0x100 * memory[RESET_VECTOR + 1]
    end

    def step
      fetch
      execute
    end

    private

    def fetch
      @opcode = memory[@pc] || 0

      if (@opcode & 0b00011111) == BXX
        @instruction = BXX
      else
        group = (@opcode & 0b00000011)
        mode  = (@opcode & 0b00011100) >> 2
        @addressing_mode = ADDRESSING_MODE_GROUPS[group][mode]
        @instruction = (@opcode & 0b11100011)
      end

      @param_lo = memory[word(@pc + 1)] || 0
      @param_hi = memory[word(@pc + 2)] || 0
      @param    = @param_hi * 0x100 + @param_lo

      @pc = word(@pc + OPCODE_SIZES[@opcode])
    end

    def execute
      execute_instruction unless execute_opcode
      time_in_cycles
    end

    def execute_opcode
      case @opcode
      when 0xE8 # INX
        @x = byte(@x + 1)
        update_zn_flags @x
      when 0xC8 # INY
        @y = byte(@y + 1)
        update_zn_flags @y
      when 0xCA # DEX
        @x = @x == 0 ? 0xFF : @x - 1
        update_zn_flags @x
      when 0x88 # DEY
        @y = @y == 0 ? 0xFF : @y - 1
        update_zn_flags @y
      when 0x4C # JMP
        @pc = @param
      when 0x6C # JMP()
        @pc = 0x100 * memory[@param + 1] + memory[@param]
      when 0xAA # TAX
        @x = @a
        update_zn_flags @x
      when 0xA8 # TAY
        @y = @a
        update_zn_flags @y
      when 0x8A # TXA
        @a = @x
        update_zn_flags @a
      when 0x98 # TYA
        @a = @y
        update_zn_flags @a
      when 0x18 # CLC
        @c = false
      when 0x38 # SEC
        @c = true
      when 0x58 # CLI
        @i = false
      when 0x78 # SEI
        @i = true
      else
        return false
      end
      true
    end

    def execute_instruction
      case @instruction
      when LDA
        @a = load
        update_zn_flags @a
      when LDX
        @x = load
        update_zn_flags @x
      when LDY
        @y = load
        update_zn_flags @y
      when STA
        store @a
      when STX
        store @x
      when STY
        store @y
      when LSR
        byte = load
        @c = byte.odd?
        store byte >> 1
        update_zn_flags byte
      when CPX
        # FIXME not sure if this is dealing with signed
        byte = load
        update_zn_flags @x - byte
        @c = @x >= byte
      when CPY
        # FIXME not sure if this is dealing with signed
        byte = load
        update_zn_flags @y - byte
        @c = @y >= byte
      when BXX # BPL, BMI, BVC, BVS, BCC, BCS, BNE, BEQ
        if should_branch?
          old_pc = pc
          @pc = word(@pc + numeric_value(@param_lo))
          @branched_same_page  = (old_pc & 0xFF00) == (@pc & 0xFF00)
          @branched_other_page = !@branched_same_page
        else
          @branched_same_page = @branched_other_page = false
        end
      end
    end

    def should_branch?
      flag     = (@opcode & 0b11000000) >> 6
      expected = (@opcode & 0b00100000) != 0
      actual   = instance_variable_get(BRANCH_FLAGS[flag])
      !(expected ^ actual)
    end

    # Read/write memory for (most) addressing modes

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

    # Timing

    def time_in_cycles
      cycles = OPCODE_CYCLE_COUNTS[@opcode]
      cycles += 1 if page_boundary_crossed?
      cycles += 1 if @branched_same_page
      cycles += 2 if @branched_other_page
      cycles
    end

    def page_boundary_crossed?
      (@opcode == 0xBE && @param_lo + @y > 0xFF) ||  # LDX; Absolute Y
      (@opcode == 0xB9 && @param_lo + @y > 0xFF) ||  # LDA; Absolute Y
      (@opcode == 0xB1 && memory[@param_lo] + @y > 0xFF) || # LDA; indirect indexed y
      (@opcode == 0xBD && @param_lo + @x > 0xFF) ||  # LDA; Absolute X
      (@opcode == 0xBC && @param_lo + @x > 0xFF)     # LDY; Absolute X
    end

    # Flag management

    def update_zn_flags(value)
      @z = (value == 0)
      @n = (value & 0b10000000 != 0)
    end

    # Two's complement conversion for byte values

    def numeric_value(signed_byte)
      signed_byte > 0x7F ? signed_byte - 0x100 : signed_byte
    end

    def signed_byte(numeric_value)
      numeric_value < 0 ? 0x100 + numeric_value  : numeric_value
    end

    # Keeping values within their bit sizes (due to lack of byte/word types)

    def byte(value)
      (value || 0) & 0xFF
    end

    def word(value)
      (value || 0) & 0xFFFF
    end

    # Debug tools

    def to_s
      "PC=#{sprintf("$%04X", @pc)} A=#{sprintf("$%02X", @a)} X=#{sprintf("$%02X", @x)} Y=#{sprintf("$%02X", @y)}"
    end
  end
end
