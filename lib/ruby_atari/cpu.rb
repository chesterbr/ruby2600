class Cpu
  attr_accessor :memory, :pc, :x, :y, :a, :flags

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
    3, 5, 0, 8, 4, 4, 6, 6, 2, 4, 2, 7, 4, 4, 7, 7,
    6, 6, 0, 8, 3, 3, 5, 5, 4, 2, 2, 2, 4, 4, 6, 6,
    2, 5, 0, 8, 4, 4, 6, 6, 2, 4, 2, 7, 4, 4, 7, 7,
    6, 6, 0, 8, 3, 3, 5, 5, 3, 2, 2, 2, 3, 4, 6, 6,
    3, 5, 0, 8, 4, 4, 6, 6, 2, 4, 2, 7, 4, 4, 7, 7,
    6, 6, 0, 8, 3, 3, 5, 5, 4, 2, 2, 2, 5, 4, 6, 6,
    2, 5, 0, 8, 4, 4, 6, 6, 2, 4, 2, 7, 4, 4, 7, 7,
    2, 6, 2, 6, 3, 3, 3, 3, 2, 2, 2, 2, 4, 4, 4, 4,
    3, 6, 0, 6, 4, 4, 4, 4, 2, 5, 2, 5, 5, 5, 5, 5,
    2, 6, 2, 6, 3, 3, 3, 3, 2, 2, 2, 2, 4, 4, 4, 4,
    2, 5, 0, 5, 4, 4, 4, 4, 2, 4, 2, 4, 4, 4, 4, 4,
    2, 6, 2, 8, 3, 3, 5, 5, 2, 2, 2, 2, 4, 4, 6, 6,
    3, 5, 0, 8, 4, 4, 6, 6, 2, 4, 2, 7, 4, 4, 7, 7,
    2, 6, 2, 8, 3, 3, 5, 5, 2, 2, 2, 2, 4, 4, 6, 6,
    2, 5, 0, 8, 4, 4, 6, 6, 2, 4, 2, 7, 4, 4, 7, 7
  ]

  def initialize
    @flags = {}
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

  # According to http://www.llx.com/~nparker/a2/opcodes.html, opcodes
  # are in form aaaabbbcc, where cc = group, bb = addressing mode, aa=opcode

  def fetch
    @opcode = memory[@pc]
    @opcode_group           = (@opcode & 0b00000011)
    @opcode_addressing_mode = (@opcode & 0b00011100) >> 2
    @opcode_instruction     = (@opcode & 0b11100000) >> 5
    @param
    @pc += INSTRUCTION_SIZE[@opcode]
  end

  def execute
    case @opcode
    when 0xA9, 0xA5, 0xB5, 0xAD, 0xBD, 0xB9, 0xB1 # LDA
      @a = read_memory
      update_zn_flags(@a)
    when 0xA2, 0xA6, 0xB6, 0xAE, 0xBE # LDX
      @x = read_memory
      update_zn_flags(@x)
    when 0xA0, 0xA4, 0xB4, 0xAC, 0xBC # LDY
      @y = read_memory
      update_zn_flags(@y)
    when 0xCA # DEX
      @x = @x == 0 ? 0xFF : @x - 1
      update_zn_flags(@x)
    when 0x88 # DEY
      @y = @y == 0 ? 0xFF : @y - 1
      update_zn_flags(@y)
    end
    time_in_cycles
  end

  def time_in_cycles
    cycles = CYCLE_COUNT[@opcode]
    cycles += 1 if page_boundary_crossed?
    cycles
  end

  def page_boundary_crossed?
    (@opcode == 0xBE && memory[@pc - 2] + @y > 0xFF) ||  # LDX; Absolute Y
    (@opcode == 0xB9 && memory[@pc - 2] + @y > 0xFF) ||  # LDA; Absolute Y
    (@opcode == 0xB1 && memory[memory[@pc - 1]] + @y > 0xFF) || # LDA; indirect indexed y
    (@opcode == 0xBD && memory[@pc - 2] + @x > 0xFF) ||  # LDA; Absolute X
    (@opcode == 0xBC && memory[@pc - 2] + @x > 0xFF)     # LDY; Absolute X
  end

  def read_memory
    case @opcode_group
    when 0b00 # BIT, JMP, STY, LDY, CPY, CPX
      case @opcode_addressing_mode
      when 0b000 then immediate_value
      when 0b001 then zero_page_value
      #when 0b010 then accumulator_value
      when 0b011 then absolute_value
      when 0b101 then zero_page_indexed_x_value
      when 0b111 then absolute_indexed_x_value
      end
    when 0b01 # ORA, AND, EOR, ADC, STA, LDA, CMP, SBC
      case @opcode_addressing_mode
      # implement ghte missing ones
      #when 0b000 then #(zero page,X)
      when 0b001 then zero_page_value
      when 0b010 then immediate_value
      when 0b011 then absolute_value
      when 0b100 then indirect_indexed_y_value
      when 0b101 then zero_page_indexed_x_value
      when 0b110 then absolute_indexed_y_value
      when 0b111 then absolute_indexed_x_value
      end
    when 0b10 # ASL, ROL, LSR, ROR, STX, LDX, DEC, INC
      case @opcode_addressing_mode
      when 0b000 then immediate_value
      when 0b001 then zero_page_value
      #when 0b010 then accumulator_value
      when 0b011 then absolute_value
      when 0b101 then zero_page_indexed_y_value # LDX only
      when 0b111 then absolute_indexed_y_value # LDX only
      end
    end
  end

  # Memory reading for instructions

  def immediate_value
    memory[@pc - 1]
  end

  def zero_page_value
    memory[memory[@pc - 1]]
  end

  def zero_page_indexed_x_value
    memory[(memory[@pc - 1] + @x) % 0x100]
  end

  def zero_page_indexed_y_value
    memory[(memory[@pc - 1] + @y) % 0x100]
  end

  def absolute_value
    memory[memory[@pc - 1] * 0x100 + memory[@pc - 2]]
  end

  def absolute_indexed_x_value
    memory[(memory[@pc - 1] * 0x100 + memory[@pc - 2] + @x) % 0x10000]
  end

  def absolute_indexed_y_value
    memory[(memory[@pc - 1] * 0x100 + memory[@pc - 2] + @y) % 0x10000]
  end

  def indirect_indexed_y_value
    memory[(memory[memory[@pc - 1]+1] * 0x100 + memory[memory[@pc - 1]] + @y) % 0x10000]
  end

  # Flag management

  def update_zn_flags(value)
    @flags[:z] = (value == 0)
    @flags[:n] = (value & 0b10000000 != 0)
  end

end
