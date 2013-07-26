module Ruby2600
  class Player < MovableObject
    attr_accessor :old_GRPn

    @graphic_delay = 5
    @graphic_size = 8
    @hmove_register = HMP0

    private

    def grp
      result = @reg[VDELP0 + @n] && @reg[VDELP0 + @n][0] == 1 ? @old_GRPn : @reg[GRP0 + @n]
      @reg[REFP0 + @n] && @reg[REFP0 + @n][3] == 1 ? reflect(result) : result
    end

    def reflect(bits)
      (0..7).inject(0) { |value, n| value + (bits[n] << (7 - n)) }
    end

    def pixel_bit
      grp[7 - @grp_bit] 
    end

    def size
      case @reg[NUSIZ0 + @n]
      when 0b101 then 2
      when 0b111 then 4
      else 1
      end
    end
  end
end

