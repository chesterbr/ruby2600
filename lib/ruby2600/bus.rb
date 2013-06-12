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

      @switch_bits = 0

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

    def reset_switch=(value)
      update_switch_bit 0, value
    end

    def select_switch=(value)
      update_switch_bit 1, value
    end

    def color_bw_switch=(value)
      update_switch_bit 3, value
    end

    def p0_difficulty_switch=(value)
      update_switch_bit 6, value
    end

    def p1_difficulty_switch=(value)
      update_switch_bit 7, value
    end

    private

    def update_switch_bit(n, value)
      if value
        @switch_bits |= 2 ** n
      else
        @switch_bits &= 0xFF - (2 ** n)
      end
      @riot.portB = @switch_bits
    end

  end
end
