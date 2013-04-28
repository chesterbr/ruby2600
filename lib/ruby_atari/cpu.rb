class Cpu
  attr_accessor :memory, :pc, :x

  RESET_VECTOR = 0xFFFC

  def reset
    self.pc = memory[RESET_VECTOR] + 0x100 * memory[RESET_VECTOR + 1]
  end

  def next
    #... decoded as DEX (baby steps!)
    self.x -= 1
    self.pc += 1
    2
  end

end
