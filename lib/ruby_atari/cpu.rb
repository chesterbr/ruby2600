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

  def fetch
    @opcode = memory[@pc]
    @pc += INSTRUCTION_SIZE[@opcode]
  end

  def execute
    # lots of refactorable repetition here, but for now...
    case @opcode
    when 0xA9 # LDA; immediate
      @a = immediate_value
      update_zero_flag(@a)
      update_negative_flag(@a)
    when 0xA5 # LDA; Zero Page
      @a = zero_page_value
      update_zero_flag(@a)
      update_negative_flag(@a)
      #asd
    when 0xB5 # LDA; Zero Page,X
      @a = zero_page_indexed_x_value
      update_zero_flag(@a)
      update_negative_flag(@a)
    when 0xAD # LDA; Absolute
      @a = absolute_value
      update_zero_flag(@a)
      update_negative_flag(@a)
    when 0xBD # LDA; Absolute,X
      @a = absolute_indexed_x_value
      update_zero_flag(@a)
      update_negative_flag(@a)
      # +1 if page boundary crossed
      return 1 + CYCLE_COUNT[@opcode] if memory[@pc - 2] + @x > 0xFF
    when 0xB9 # LDA; Absolute,Y
      @a = memory[(memory[@pc - 1] * 0x100 + memory[@pc - 2] + @y) % 0x10000]
      update_zero_flag(@a)
      update_negative_flag(@a)
      # +1 if page boundary crossed
      return 1 + CYCLE_COUNT[@opcode] if memory[@pc - 2] + @y > 0xFF
    when 0xA2, 0xA6, 0xB6, 0xAE, 0xBE # LDX
      @x = read_memory
      update_zero_flag(@x)
      update_negative_flag(@x)
      return 1 + CYCLE_COUNT[@opcode] if mem_boundary_crossed?
    when 0xA0, 0xA4, 0xB4, 0xAC, 0xBC # LDY
      @y = read_memory
      update_zero_flag(@y)
      update_negative_flag(@y)
      return 1 + CYCLE_COUNT[@opcode] if mem_boundary_crossed?
    when 0xCA # DEX
      @x = @x == 0 ? 0xFF : @x - 1
      update_zero_flag(@x)
      update_negative_flag(@x)
    when 0x88 # DEY
      @y = @y == 0 ? 0xFF : @y - 1
      update_zero_flag(@y)
      update_negative_flag(@y)
    end
    CYCLE_COUNT[@opcode]
  end

  # http://www.llx.com/~nparker/a2/opcodes.html

  def read_memory
    # aaaabbbcc
    # cc=10
    bbb = (@opcode & 0b00011100) >> 2
    cc  = (@opcode & 0b00000011)
    case cc
    when 0b00 # BIT, JMP, STY, LDY, CPY, CPX
      case bbb
      when 0b000 then immediate_value
      when 0b001 then zero_page_value
      #when 0b010 then accumulator_value
      when 0b011 then absolute_value
      when 0b101 then zero_page_indexed_x_value
      when 0b111 then absolute_indexed_x_value
      end
    when 0b10 # ASL, ROL, LSR, ROR, STX, LDX, DEC, INC
      case bbb
      when 0b000 then immediate_value
      when 0b001 then zero_page_value
      #when 0b010 then accumulator_value
      when 0b011 then absolute_value
      when 0b101 then zero_page_indexed_y_value # LDX only
      when 0b111 then absolute_indexed_y_value # LDX only
      end
    end
  end

  def mem_boundary_crossed?
    (@opcode == 0xBE && memory[@pc - 2] + @y > 0xFF) ||  # LDX; Absolute Y && page boundary crossed
    (@opcode == 0xBC && memory[@pc - 2] + @x > 0xFF)     # LDY; Absolute X && page boundary crossed
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

  # Flag management

  def update_zero_flag(value)
    @flags[:z] = (value == 0)
  end

  def update_negative_flag(value)
    @flags[:n] = (value & 0b10000000 != 0)
  end

end
