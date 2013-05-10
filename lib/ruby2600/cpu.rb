class Cpu
  attr_accessor :memory
  attr_accessor :pc, :a, :x, :y
  attr_accessor :n, :v, :b, :d, :i, :z, :c    # Flags (P) bits (P=nv-bdizc)

  RESET_VECTOR = 0xFFFC

  # FIXME tables generated from CPU simuulator, may be inaccurate. See:
  #       http://visual6502.org/wiki/index.php?title=6502_all_256_Opcodes

  INSTRUCTION_SIZE = [
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

  CYCLE_COUNT = [
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

  # Opcodes are in form aaaabbbcc, where cc = group, bb = mode for group
  # (see: http://www.llx.com/~nparker/a2/opcodes.html)

  ADDRESSING_MODE = [
    # group 0b00: BIT, JMP, JMP(), STY, LDY, CPY, CPX
    [
      :immediate,
      :zero_page,
      nil,
      :absolute,
      nil,
      :zero_page_indexed_x,
      nil,
      :absolute_indexed_x
    ],
    # group 0b01: ORA, AND, EOR, ADC, STA, LDA, CMP, SBC
    [
      :indexed_indirect_x,
      :zero_page,
      :immediate,
      :absolute,
      :indirect_indexed_y,
      :zero_page_indexed_x,
      :absolute_indexed_y,
      :absolute_indexed_x,
    ],
    # group 0b10: ASL, ROL, LSR, ROR, STX, LDX, DEC, INC
    [
      :immediate,
      :zero_page,
      :accumulator,
      :absolute,
      nil,
      :zero_page_indexed_y, # FIXME: these _y are for LDX
      nil,                  #        and STX only, will fail
      :absolute_indexed_y   #        with e.g.  ASL (should be _x)
    ]
  ]

  def initialize
    @x = @y = @a = 0
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

    group = (@opcode & 0b00000011)
    mode  = (@opcode & 0b00011100) >> 2
    @addressing_mode = ADDRESSING_MODE[group][mode]

    @param_lo = memory[@pc + 1] || 0
    @param_hi = memory[@pc + 2] || 0
    @param    = @param_hi * 0x100 + @param_lo

    @pc += INSTRUCTION_SIZE[@opcode]
  end

  def execute
    case @opcode
    when 0xA9, 0xA5, 0xB5, 0xAD, 0xBD, 0xB9, 0xB1, 0xA1 # LDA
      @a = load
      update_zn_flags @a
    when 0xA2, 0xA6, 0xB6, 0xAE, 0xBE # LDX
      @x = load
      update_zn_flags @x
    when 0xA0, 0xA4, 0xB4, 0xAC, 0xBC # LDY
      @y = load
      update_zn_flags @y
    when 0x85, 0x95, 0x8D, 0x9D, 0x99, 0x81, 0x91 # STA
      store @a
    when 0x86, 0x96, 0x8E # STX
      store @x
    when 0x84, 0x94, 0x8C # STY
      store @y
    when 0xE8 # INX
      @x = (@x + 1) & 0xFF
      update_zn_flags @x
    when 0xC8 # INY
      @y = (@y + 1) & 0xFF
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
    when 0xB0 # BCS
      @old_pc = @pc
      @pc += numeric_value(@param_lo) if c
    when 0xD0 # BNE
      @old_pc = @pc
      @pc += numeric_value(@param_lo) unless z
    end
    time_in_cycles
  end

  def numeric_value(signed_byte)
    signed_byte > 0x7F ? -(signed_byte ^ 0xFF) - 1 : signed_byte
  end

  def load
    case @addressing_mode
    when :immediate   then @param_lo
    when :accumulator then @a
    else              memory[self.send(@addressing_mode)]
    end
  end

  def store(value)
    case @addressing_mode
    when :immediate   then memory[@param_lo] = value
    when :accumulator then @a = value
    else              memory[self.send(@addressing_mode)] = value
    end
  end

  # Timing

  def time_in_cycles
    cycles = CYCLE_COUNT[@opcode]
    cycles += 1 if page_boundary_crossed?
    cycles += 1 if branch_to_same_page?
    cycles += 2 if branch_to_other_page?
    cycles
  end

  def page_boundary_crossed?
    (@opcode == 0xBE && @param_lo + @y > 0xFF) ||  # LDX; Absolute Y
    (@opcode == 0xB9 && @param_lo + @y > 0xFF) ||  # LDA; Absolute Y
    (@opcode == 0xB1 && memory[memory[@pc - 1]] + @y > 0xFF) || # LDA; indirect indexed y
    (@opcode == 0xBD && @param_lo + @x > 0xFF) ||  # LDA; Absolute X
    (@opcode == 0xBC && @param_lo + @x > 0xFF)     # LDY; Absolute X
  end

  def branch_to_same_page?
    (@opcode == 0xB0 &&  @c && (@old_pc & 0xFF00) == (@pc & 0xFF00)) || # BCS
    (@opcode == 0xD0 && !@z && (@old_pc & 0xFF00) == (@pc & 0xFF00))    # BNE
  end

  def branch_to_other_page?
    (@opcode == 0xB0 &&  @c && (@old_pc & 0xFF00) != (@pc & 0xFF00)) || # BCS
    (@opcode == 0xD0 && !@z && (@old_pc & 0xFF00) != (@pc & 0xFF00))    # BNE
  end

  # Formulae for (most) memory addressing modes

  def zero_page
    @param_lo
  end

  def zero_page_indexed_x
    (@param_lo + @x) % 0x100
  end

  def zero_page_indexed_y
    (@param_lo + @y) % 0x100
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

  def indirect_indexed_y
    (memory[@param_lo + 1] * 0x100 + memory[@param_lo] + @y) % 0x10000
  end

  def indexed_indirect_x
    indexed_param = (@param_lo + @x) % 0x100
    memory[indexed_param + 1] * 0x100 + memory[indexed_param]
  end

  # Flag management

  def update_zn_flags(value)
    @z = (value == 0)
    @n = (value & 0b10000000 != 0)
  end

end
