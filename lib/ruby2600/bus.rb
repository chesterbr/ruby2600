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
      @tia.riot = riot
      cpu.reset
    end

    # FIXME dry

    def [](address)
      if address[12] == 1
        return @cart[address & 0x0FFF]
      elsif address[7] == 1
        if address[9] == 0
          return @riot[address & 0x7F]
        else
          return @riot[address & 0x2FF]
        end
      else
        return @tia[address & 0x3F]
      end
    end

    def []=(address, value)
      if address[12] == 1
        @cart[address & 0x0FFF] = value
      elsif address[7] == 1
        if address[9] == 0
          @riot[address & 0x7F] = value
        else
          @riot[address & 0x2FF] = value
        end
      else
        @tia[address & 0x3F] = value
      end
    end

    def color_bw_switch=(value)
      @riot.portB = value ? 0b00001000 : 0
    end

  end
end
