class Cpu
  attr_accessor :memory, :pc, :x, :y, :flags

  RESET_VECTOR = 0xFFFC

  def initialize
    @flags = {}
    @x = @y = 0
  end

  def reset
    @pc = memory[RESET_VECTOR] + 0x100 * memory[RESET_VECTOR + 1]
  end

  def fetch
    @opcode = memory[@pc]
    #... still not worrying (DEX=DEY=1 byte)
    @pc += 1
  end

  def execute
    # lots of refactorable repetition here, but for now...
    case @opcode
    when 0xCA # DEX
      @x = @x == 0 ? 0xFF : @x - 1
      @flags[:z] = (@x == 0)
      @flags[:n] = (@x & 0b10000000 != 0)
      2
    when 0x88 # DEY
      @y = @y == 0 ? 0xFF : @y - 1
      @flags[:z] = (@y == 0)
      @flags[:n] = (@y & 0b10000000 != 0)
      2
    end
  end
end
