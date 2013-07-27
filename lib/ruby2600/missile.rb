module Ruby2600
  class Missile < MovableObject

    @graphic_delay = 4
    @graphic_size = 1
    @hmove_register = HMP0
    @color_register = COLUP0

    private

    def pixel_bit
      reg(ENAM0)[1]
    end

    def size
    	2 ** (reg(NUSIZ0)[5] * 2 + reg(NUSIZ0)[4])
    end
  end
end