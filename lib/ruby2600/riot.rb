module Ruby2600
  class Riot
    def initialize
      @ram = Array.new(128)
    end

    def [](position)
      @ram[position - 0x80]
    end

    def []=(position, value)
      @ram[position - 0x80] = value
    end
  end
end
