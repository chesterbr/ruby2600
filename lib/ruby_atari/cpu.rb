class Cpu
  attr_accessor :memory, :pc

  RESET_VECTOR = 0xFFFC

  def reset
    self.pc = memory[RESET_VECTOR] + 0x100 * memory[RESET_VECTOR + 1]
  end

end
