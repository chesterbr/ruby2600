module Ruby2600
  class TIA
    attr_accessor :cpu, :riot

    include Constants

    # A scanline "lasts" 228 "color clocks" (CLKs), of which 68
    # are the horizontal blank period, and 160 are visible pixels

    HORIZONTAL_BLANK_CLK_COUNT = 68
    VISIBLE_CLK_COUNT = 160

    def initialize
      # Real 2600 starts with random values (and Stella comments warn
      # about games that crash if we start with all zeros)
      @reg = Array.new(64) { rand(256) }

      @p0 = Player.new(@reg, 0)
      @p1 = Player.new(@reg, 1)
      @m0 = Missile.new(@reg, 0)
      @m1 = Missile.new(@reg, 1)
      @bl = Ball.new(@reg)
      @pf = Playfield.new(@reg)

      # FIXME maybe bus should initialize this properly?
      @reg[INPT4] = 0xFF # Button 0 released

      # Playfield position counter is fixed (and never changes)
      @pf.value = 0 
    end

    def [](position)
      @reg[position] if position.between?(CXM0P, INPT5)
    end

    def []=(position, value)
      case position
      when RESP0
        @p0.strobe
      when RESP1
        @p1.strobe
      when RESM0
        @m0.strobe
      when RESM1
        @m1.strobe
      when RESBL
        @bl.strobe
      when HMOVE
        @late_reset_hblank = true
        @p0.start_hmove
        @p1.start_hmove
        @m0.start_hmove
        @m1.start_hmove
        @bl.start_hmove
      when HMCLR
        @reg[HMP0] = @reg[HMP1] = @reg[HMM0] = @reg[HMM1] = @reg[HMBL] = 0
      when CXCLR
        @reg[CXM0P] = @reg[CXM1P] = @reg[CXP0FB] = @reg[CXP1FB] = @reg[CXM0FB] = @reg[CXM1FB] = @reg[CXBLPF] = @reg[CXPPMM] = 0
      when WSYNC
        @cpu.halted = true
      else
        @reg[position] = value # FIXME it's not the grape party!
      end
      @p0.old_value = @reg[GRP0]  if position == GRP1
      @bl.old_value = @reg[ENABL] if position == GRP1
      @p1.old_value = @reg[GRP1]  if position == GRP0
    end

    def scanline
      intialize_scanline
      wait_horizontal_blank
      draw_scanline
    end

    def frame
      buffer = []
      scanline while vertical_sync?                 # VSync
      scanline while vertical_blank?                # VBlank
      buffer << scanline until vertical_blank?      # Picture
      scanline until vertical_sync?                 # Overscan
      buffer
    end

    private

    def intialize_scanline
      @cpu.halted = false
      @late_reset_hblank = false      
    end

    def wait_horizontal_blank
      HORIZONTAL_BLANK_CLK_COUNT.times { |color_clock| sync_2600_with color_clock }
    end

    def draw_scanline
      scanline = Array.new(160, 0)
      VISIBLE_CLK_COUNT.times do |pixel|
        color_clock = pixel + HORIZONTAL_BLANK_CLK_COUNT
        extended_hblank = @late_reset_hblank && pixel < 8

        fetch_fixed_object_pixels
        fetch_movable_object_pixels unless extended_hblank
        update_collision_flags

        scanline[pixel] = topmost_pixel unless vertical_blank? || extended_hblank
        
        sync_2600_with color_clock
      end
      scanline
    end

    def fetch_fixed_object_pixels
      @pf_pixel = @pf.pixel
      @bk_pixel = @reg[COLUBK]
    end

    def fetch_movable_object_pixels
      @p0_pixel = @p0.pixel
      @p1_pixel = @p1.pixel
      @m0_pixel = @m0.pixel
      @m1_pixel = @m1.pixel
      @bl_pixel = @bl.pixel
    end

    def topmost_pixel
      if @reg[CTRLPF][2].zero?
        @p0_pixel || @m0_pixel || @p1_pixel || @m1_pixel || @bl_pixel || @pf_pixel || @bk_pixel
      else
        @pf_pixel || @bl_pixel || @p0_pixel || @m0_pixel || @p1_pixel || @m1_pixel || @bk_pixel
      end
    end

    BIT_6 = 0b01000000
    BIT_7 = 0b10000000

    def update_collision_flags
      @reg[CXM0P]  |= BIT_6 if @m0_pixel && @p0_pixel
      @reg[CXM0P]  |= BIT_7 if @m0_pixel && @p1_pixel
      @reg[CXM1P]  |= BIT_6 if @m1_pixel && @p1_pixel
      @reg[CXM1P]  |= BIT_7 if @m1_pixel && @p0_pixel
      @reg[CXP0FB] |= BIT_6 if @p0_pixel && @bl_pixel
      @reg[CXP0FB] |= BIT_7 if @p0_pixel && @pf_pixel
      @reg[CXP1FB] |= BIT_6 if @p1_pixel && @bl_pixel
      @reg[CXP1FB] |= BIT_7 if @p1_pixel && @pf_pixel
      @reg[CXM0FB] |= BIT_6 if @m0_pixel && @bl_pixel
      @reg[CXM0FB] |= BIT_7 if @m0_pixel && @pf_pixel
      @reg[CXM1FB] |= BIT_6 if @m1_pixel && @bl_pixel
      @reg[CXM1FB] |= BIT_7 if @m1_pixel && @pf_pixel
      # c-c-c-combo breaker: bit 6 of CXM1FB is unused
      @reg[CXBLPF] |= BIT_7 if @bl_pixel && @pf_pixel
      @reg[CXPPMM] |= BIT_6 if @m0_pixel && @m1_pixel
      @reg[CXPPMM] |= BIT_7 if @p0_pixel && @p1_pixel
    end

    # All Atari chips use the same crystal for their clocks (with RIOT and
    # CPU running at 1/3 of TIA speed). 

    # Since the emulator's "main loop" is based on TIA#scanline, we'll "tick"
    # the other chips here (and also apply the horizontal motion on movable
    # objects at 1/4 of TIA speed, just like the hardware does)

    def sync_2600_with(color_clock)
      riot.tick if color_clock % 3 == 0
      if color_clock % 4 == 0 # FIXME assuming H@1 postition here, might need adjustment
        @p0.apply_hmove
        @p1.apply_hmove
        @m0.apply_hmove
        @m1.apply_hmove
        @bl.apply_hmove
      end
      cpu.tick if color_clock % 3 == 2
    end

    def vertical_blank?
      @reg[VBLANK] & 0b00000010 != 0
    end

    def vertical_sync?
      @reg[VSYNC] & 0b00000010 != 0
    end
  end
end


