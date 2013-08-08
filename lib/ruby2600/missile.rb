module Ruby2600
  class Missile < Graphic

    @graphic_delay = 4
    @graphic_size = 1
    @hmove_register = HMM0
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