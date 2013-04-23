class Riot
  def initialize
    @ram = Array.new(128)
  end

  def read(position)
    @ram[position - 0x80] if position.between? 0x80, 0xFF
  end

  def write(position, value)
    @ram[position - 0x80] = value if position.between? 0x80, 0xFF
  end
end
