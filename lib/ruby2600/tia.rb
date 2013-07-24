module Ruby2600
  class TIA
    attr_accessor :cpu, :riot

    include Constants

    # A scanline "lasts" 228 "color clocks" (CLKs), of which 68
    # are the initial blank period

    HORIZONTAL_BLANK_CLK_COUNT = 68
    TOTAL_SCANLINE_CLK_COUNT = 228

    # Maps which register/bit should be set for each playfield pixel

    PLAYFIELD_ORDER = [[PF0, 4], [PF0, 5], [PF0, 6], [PF0, 7],
                       [PF1, 7], [PF1, 6], [PF1, 5], [PF1, 4], [PF1, 3], [PF1, 2], [PF1, 1], [PF1, 0],
                       [PF2, 0], [PF2, 1], [PF2, 2], [PF2, 3], [PF2, 4], [PF2, 5], [PF2, 6], [PF2, 7]]

    def initialize
      @reg = Array.new(32) { rand(256) }
      @cpu_credits = 0
      #@bl_counter = MovableObject.new
      # @bl_counter.on_change { |value| bl_counter_increased(value) }
      #@bl_pixels_to_draw = 0
      @p0 = Player.new(@reg, 0)
      @p1 = Player.new(@reg, 1)
    end

    def [](position)

    end

    def []=(position, value)
      case position
      when RESP0
        @p0.strobe
      when RESP1
        @p1.strobe
      when HMOVE
        @late_reset_hblank = true
        @p0.start_hmove
        @p1.start_hmove
        #@bl_counter.move @reg[HMBL]
      when HMCLR
        @reg[HMP0] = @reg[HMP1] = 0
      when WSYNC
        @cpu.halted = true
      else
        @reg[position] = value
      end
      @p1.old_GRPn = @reg[GRP1] if position == GRP0
      @p0.old_GRPn = @reg[GRP0] if position == GRP1
    end

    def scanline
      intialize_scanline
      wait_horizontal_blank
      draw_scanline
    end

    def frame
      buffer = []
      scanline while vertical_sync?
      buffer << scanline until vertical_sync?
      buffer
    end

    private

    def intialize_scanline
      @cpu.halted = false
      @late_reset_hblank = false
      @scanline = Array.new(160, 0)
      @pixel = 0
    end

    def wait_horizontal_blank
      HORIZONTAL_BLANK_CLK_COUNT.times { |color_clock| sync_2600_with color_clock }
    end

    def draw_scanline
      HORIZONTAL_BLANK_CLK_COUNT.upto TOTAL_SCANLINE_CLK_COUNT - 1 do |color_clock|
        sync_2600_with color_clock
        if @late_reset_hblank && @pixel < 8
          @pixel += 1
          next
        end
        unless vertical_blank?
          @scanline[@pixel] = player_pixel || pf_pixel || bg_pixel
        end
        @pixel += 1
      end
      @scanline
    end

    # All Atari chips use the same crystal for their clocks (with RIOT and
    # CPU running at 1/3 of TIA speed). 

    # Since the emulator's "main loop" is based on TIA#scanline, we'll "tick"
    # the other chips here (and also apply the horizontal motion on movable
    # objects, just like the hardware does)

    def sync_2600_with(color_clock)
      riot.tick if color_clock % 3 == 0
      if color_clock % 4 == 0 # FIXME assuming H@1 postition here, might need adjustment
        @p0.apply_hmove
        @p1.apply_hmove
      end
      cpu.tick if color_clock % 3 == 2
    end

    def vertical_blank?
      @reg[VBLANK] & 0b00000010 != 0
    end

    def vertical_sync?
      @reg[VSYNC] & 0b00000010 != 0
    end

    # Background

    def bg_pixel
      @reg[COLUBK]
    end

    # Playfield

    def pf_pixel
      pf_color if pf_bit_set?
    end

    def pf_color
      @reg[score_mode? ? COLUP0 + @pixel / 80 : COLUPF]
    end

    def pf_bit_set?
      pf_pixel = (@pixel / 4) % 20
      pf_pixel = 19 - pf_pixel if reflect_current_side?
      register, bit = PLAYFIELD_ORDER[pf_pixel]
      @reg[register][bit] == 1
    end

    def reflect_current_side?
      @reg[CTRLPF][0] == 1 && @pixel > 79
    end

    def score_mode?
      @reg[CTRLPF][1] == 1
    end

    # Ball

    # def bl_pixel
    #   return nil unless @reg[ENABL][1]==1 && @bl_pixels_to_draw > 0
    #   @bl_pixels_to_draw -= 1
    #   @reg[COLUPF]
    # end

    # def bl_size
    #   2 ** (2 * @reg[CTRLPF][5] + @reg[CTRLPF][4])
    # end

    # def bl_counter_increased(value)
    #   if value == 0
    #     @bl_pixels_to_draw = [bl_size, 4].min
    #   elsif value == 1 && bl_size == 8
    #     @bl_pixels_to_draw = 4
    #   else
    #     @bl_pixels_to_draw = 0
    #   end
    # end

    # Players
    # (need to request both pixels to keep counters in sync,
    #  even if one overrides the other)

    def player_pixel
      p0_pixel = @p0.pixel
      p1_pixel = @p1.pixel
      p0_pixel || p1_pixel
    end
  end
end


