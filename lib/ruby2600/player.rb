module Ruby2600
  class Player < Graphic

    @graphic_delay = 5
    @graphic_size = 8
    @hmove_register = HMP0
    @color_register = COLUP0

    private

    def pixel_bit
      grp[7 - @grp_bit]
    end

    def size
      case reg(NUSIZ0) & 0b111
      when 0b101 then 2
      when 0b111 then 4
      else 1
      end
    end

    def grp
      result = reg(VDELP0)[0] == 1 ? @old_value : reg(GRP0)
      reg(REFP0)[3] == 1 ? reflect(result) : result
    end

    def reflect(bits)
      (0..7).inject(0) { |value, n| value + (bits[n] << (7 - n)) }
    end
  end
end

