class Riot
  def initialize
    @ram = Array.new(128)
  end

  def read(position)
    @ram[position - 0x80]
  end

  def write(position, value)
    @ram[position - 0x80] = value
  end
end
