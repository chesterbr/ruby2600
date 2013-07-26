module Ruby2600
  class Missile < MovableObject

    @graphic_delay = 4
    @graphic_size = 1
    @hmove_register = HMP0

    private

    def pixel_bit
      @reg[ENAM0 + @n][1]
    end

    def size
    	2 ** (@reg[NUSIZ0 + @n][5] * 2 + @reg[NUSIZ0 + @n][4])
    end
  end
end