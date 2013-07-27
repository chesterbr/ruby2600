module Ruby2600
  class Ball < MovableObject

    @graphic_delay = 4
    @graphic_size = 1
    @hmove_register = HMBL
    @color_register = COLUPF

    # Ball draws immediately when strobed (other objects only do it
    # when their counter wraps around, i.e., on next scanline)
    def strobe
      super()
      on_counter_change
    end

    private

    def pixel_bit
      reg(VDELBL)[0] == 1 ? @old_value[1] : reg(ENABL)[1]
    end

    def size
    	2 ** (reg(CTRLPF)[5] * 2 + reg(CTRLPF)[4])
    end

    def should_draw_copy?
      false
    end
  end
end