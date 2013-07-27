module Ruby2600
  class Ball < MovableObject

    @graphic_delay = 4
    @graphic_size = 1
    @hmove_register = HMBL
    @color_register = COLUPF

    private

    def pixel_bit
      reg(ENABL)[1]
    end

    def size
    	2 ** (reg(CTRLPF)[5] * 2 + reg(CTRLPF)[4])
    end

    def should_draw_copy?
      false
    end
  end
end