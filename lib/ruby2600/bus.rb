module Ruby2600
  class Bus
    attr_accessor :tia

    MASK_6507_ADDRESS = 0b0001111111111111 # cheapo 6507 has no A14-A16

    def initialize(cpu, tia, cart, riot)
      @cpu = cpu
      @tia  = tia
      @cart = cart
      @riot = riot

      @cpu.memory = self
      @tia.cpu = cpu
      cpu.reset
    end

    def [](address)
      address &= MASK_6507_ADDRESS
      if address[12] == 1
        return @cart[address]
      elsif address[7] == 1
        return @riot[address & 0x7F]
      else
        return @tia[address & 0x3F]
      end
    end

    def []=(address, value)
      return if address[12] == 1
      address = address & MASK_6507_ADDRESS
      if address[7] == 0
        @tia[address & 0x3F] = value
      else
        @riot[address & 0x7F] = value
      end
    end
  end
end
