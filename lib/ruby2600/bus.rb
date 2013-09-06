module Ruby2600
  class Bus
    include Constants

    attr_accessor :tia

    def initialize(cpu, tia, cart, riot)
      @cpu = cpu
      @tia  = tia
      @cart = cart
      @riot = riot

      @cpu.memory = self
      @tia.cpu = cpu
      @tia.riot = riot

      @riot_bit_states = {
        :portA => 0xFF,
        :portB => 0xFF
      }
      refresh_riot :portA
      refresh_riot :portB

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
        return @tia[(address & 0x0F) + 0x30]
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

    def reset_switch=(state)
      set_riot :portB, 0, state
    end

    def select_switch=(state)
      set_riot :portB, 1, state
    end

    def color_bw_switch=(state)
      set_riot :portB, 3, state
    end

    def p0_difficulty_switch=(state)
      set_riot :portB, 6, state
    end

    def p1_difficulty_switch=(state)
      set_riot :portB, 7, state
    end

    def p0_joystick_up=(state)
      set_riot :portA, 4, state
    end

    def p0_joystick_down=(state)
      set_riot :portA, 5, state
    end

    def p0_joystick_left=(state)
      set_riot :portA, 6, state
    end

    def p0_joystick_right=(state)
      set_riot :portA, 7, state
    end

    def p0_joystick_fire=(state)
      @tia.set_port_level 4, (state ? :low : :high)
    end

    private

    def set_riot(port, n, state)
      # To press/enable something, we reset the bit, and vice-versa.
      # Why? Because TIA, that's why.
      if state
        @riot_bit_states[port] &= 0xFF - (1 << n)
      else
        @riot_bit_states[port] |= 1 << n
      end
      refresh_riot port
    end

    def refresh_riot(port)
      @riot.send("#{port}=", @riot_bit_states[port])
    end



  end
end
