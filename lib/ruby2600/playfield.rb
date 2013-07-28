# Playfield isn't really *movable*, and could be drawn directly as the
# TIA class draws the scanline, but giving it its own class and counter
# simplifies testing and pushes class TIA towards SRP

module Ruby2600
  class Playfield < MovableObject

  	@color_register = COLUPF

  	# register+bit map for each playfield pixel

  	REG_AND_BIT_FOR_PIXEL = [[PF0, 4], [PF0, 5], [PF0, 6], [PF0, 7],
  	                         [PF1, 7], [PF1, 6], [PF1, 5], [PF1, 4], [PF1, 3], [PF1, 2], [PF1, 1], [PF1, 0],
  	                         [PF2, 0], [PF2, 1], [PF2, 2], [PF2, 3], [PF2, 4], [PF2, 5], [PF2, 6], [PF2, 7]]

  	private

    def update_pixel_bit
      pf_pixel = value % 20
      pf_pixel = 19 - pf_pixel if reflect?
      register, bit = REG_AND_BIT_FOR_PIXEL[pf_pixel]
      @pixel_bit = reg(register)[bit]
    end

    def on_counter_change
   	  self.class.color_register = score_mode? ? COLUP0 + value / 20 : COLUPF
    end

    def reflect?
      reg(CTRLPF)[0] == 1 && value > 19
    end

    def score_mode?
      reg(CTRLPF)[1] == 1
    end
  end
end

