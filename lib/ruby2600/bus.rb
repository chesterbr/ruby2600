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

    def reset_switch=(bool_state)
      set_riot :portB, 0, bool_state
    end

    def select_switch=(bool_state)
      set_riot :portB, 1, bool_state
    end

    def color_bw_switch=(bool_state)
      set_riot :portB, 3, bool_state
    end

    def p0_difficulty_switch=(bool_state)
      set_riot :portB, 6, bool_state
    end

    def p1_difficulty_switch=(bool_state)
      set_riot :portB, 7, bool_state
    end

    def p0_joystick_up=(bool_state)
      set_riot :portA, 4, bool_state
    end

    def p0_joystick_down=(bool_state)
      set_riot :portA, 5, bool_state
    end

    def p0_joystick_left=(bool_state)
      set_riot :portA, 6, bool_state
    end

    def p0_joystick_right=(bool_state)
      set_riot :portA, 7, bool_state
    end

    private

    def set_riot(port, n, bool_state)
      # To press/enable something, we reset the bit, and vice-versa.
      # Why? Because TIA, that's why.
      if bool_state
        @switch_bits &= 0xFF - (2 ** n)
      else
        @switch_bits |= 2 ** n
      end
      @riot.send("#{port}=", @switch_bits)
    end

  end
end
