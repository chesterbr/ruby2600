module Ruby2600
  class Bus
    attr_accessor :tia

    def initialize(cpu, tia, cart, riot)
      @cpu = cpu
      @tia  = tia
      @cart = cart
      @riot = riot

      @cpu.memory = self
      @tia.cpu = cpu
      cpu.reset
    end

    # FIXME dry

    def [](address)
      if address[12] == 1
        return @cart[address & 0x0FFF]
      elsif address[7] == 1
        return @riot.ram[address & 0x7F]
      else
        return @tia[address & 0x3F]
      end
    end

    def []=(address, value)
      if address[12] == 1
        @cart[address & 0x0FFF] = value
      elsif address[7] == 1
        @riot.ram[address & 0x7F] = value
      else
        @tia[address & 0x3F] = value
      end
    end
  end
end
