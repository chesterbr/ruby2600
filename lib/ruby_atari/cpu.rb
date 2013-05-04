class Cpu
  attr_accessor :memory, :pc, :x, :y, :flags

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
    @x = @y = 0
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
    when 0xA2 # LDX, immediate
      @x = memory[@pc - 1]
      update_zero_flag(@x)
      update_negative_flag(@x)
    when 0xA6 # LDX, Zero Page
      @x = memory[memory[@pc - 1]]
      update_zero_flag(@x)
      update_negative_flag(@x)
    when 0xB6 # LDX, Zero Page,Y
      @x = memory[memory[@pc - 1] + @y]
      update_zero_flag(@x)
      update_negative_flag(@x)
    when 0xAE # LDX, Absolute
      @x = memory[memory[@pc - 1] * 0x100 + memory[@pc - 2]]
      update_zero_flag(@x)
      update_negative_flag(@x)
    when 0xBE # LDX, Absolute,Y
      @x = memory[memory[@pc - 1] * 0x100 + memory[@pc - 2] + @y]
      update_zero_flag(@x)
      update_negative_flag(@x)
      # +1 if page boundary crossed
      # FIXME on LDX this is fine, but fetch memory[@pc -2] before
      #       any memory-changing operation
      return 1 + CYCLE_COUNT[@opcode] if memory[@pc - 2] + @y > 0xFF
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

  def update_zero_flag(value)
    @flags[:z] = (value == 0)
  end

  def update_negative_flag(value)
    @flags[:n] = (value & 0b10000000 != 0)
  end

end
