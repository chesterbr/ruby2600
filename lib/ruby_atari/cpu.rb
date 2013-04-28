class Cpu
  attr_accessor :memory, :pc, :x, :flags

  RESET_VECTOR = 0xFFFC

  def initialize
    @flags = {}
  end

  def reset
    @pc = memory[RESET_VECTOR] + 0x100 * memory[RESET_VECTOR + 1]
  end

  def fetch
    #... decoded as DEX (baby steps!)
    @pc += 1

  end

  def execute
    #... decoded as DEX (baby steps!)
    @x = @x == 0 ? 0xFF : @x - 1
    @flags[:z] = (@x == 0)
    @flags[:n] = (@x & 0b10000000 != 0)
    @flags
    2
  end
end
