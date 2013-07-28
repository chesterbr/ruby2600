module Ruby2600
  # Of course, the Playfield is not a *movable* object, and its drawing
  # is synced with the main scanline counter. But moving it to a separate
  # class with its own counter makes sense, and pushes class TIA towards SRP
  class Playfield < MovableObject

  	# Maps which register/bit should be set for each playfield pixel

  	PLAYFIELD_ORDER = [[PF0, 4], [PF0, 5], [PF0, 6], [PF0, 7],
  	                   [PF1, 7], [PF1, 6], [PF1, 5], [PF1, 4], [PF1, 3], [PF1, 2], [PF1, 1], [PF1, 0],
  	                   [PF2, 0], [PF2, 1], [PF2, 2], [PF2, 3], [PF2, 4], [PF2, 5], [PF2, 6], [PF2, 7]]

  	private

    def update_pixel_bit
      pf_pixel = value % 20
      pf_pixel = 19 - pf_pixel if reflect?
      register, bit = PLAYFIELD_ORDER[pf_pixel]
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

