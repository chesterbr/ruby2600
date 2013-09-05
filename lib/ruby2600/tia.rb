module Ruby2600
  class TIA
    attr_accessor :cpu, :riot
    attr_reader :reg, :scanline_stage

    include Constants

    # A scanline "lasts" 228 "color clocks" (CLKs), of which 68
    # are the horizontal blank period, and 160 are visible pixels

    HORIZONTAL_BLANK_CLK_COUNT = 68
    VISIBLE_CLK_COUNT = 160

    def initialize
      # Real 2600 starts with random values (and Stella comments warn
      # about games that crash if we start with all zeros)
      @reg = Array.new(64) { rand(256) }

      @p0 = Player.new(self, 0)
      @p1 = Player.new(self, 1)
      @m0 = Missile.new(self, 0)
      @m1 = Missile.new(self, 1)
      @bl = Ball.new(self)
      @pf = Playfield.new(self)
      @graphics = [@p0, @p1, @m0, @m1, @bl, @pf]

      @port_level = Array.new(6, false)
      @latch_level = Array.new(6, true)
    end

    def frame
      buffer = []
      scanline while vertical_sync?                 # VSync
      scanline while vertical_blank?                # VBlank
      buffer << scanline until vertical_blank?      # Picture
      scanline until vertical_sync?                 # Overscan
      @frame_counter.track_fps if @frame_counter
      buffer
    end

    def scanline
      intialize_scanline
      wait_horizontal_blank
      draw_scanline
    end

    def set_port_level(number, level)
      @port_level[number] = (level == :high)
      @latch_level[number] = false if level == :low
    end

    # Accessors for games (other classes should use :reg to avoid side effects)

    def [](position)
      case position
      when CXM0P..CXPPMM then @reg[position]
      when INPT0..INPT5  then value_for_port(position - INPT0)
      end
    end

    def []=(position, value)
      case position
      when RESP0
        @p0.reset
      when RESP1
        @p1.reset
      when RESM0
        @m0.reset
      when RESM1
        @m1.reset
      when RESBL
        @bl.reset
      when RESMP0
        @m0.reset_to @p0
      when RESMP1
        @m1.reset_to @p1
      when HMOVE
        @late_reset_hblank = true
        @graphics.each &:start_hmove
      when HMCLR
        @reg[HMP0] = @reg[HMP1] = @reg[HMM0] = @reg[HMM1] = @reg[HMBL] = 0
      when CXCLR
        @reg[CXM0P] = @reg[CXM1P] = @reg[CXP0FB] = @reg[CXP1FB] = @reg[CXM0FB] = @reg[CXM1FB] = @reg[CXBLPF] = @reg[CXPPMM] = 0
      when WSYNC
        @cpu.halted = true
      when VSYNC..VDELBL
        @reg[position] = value
      end
      @p0.old_value = @reg[GRP0]  if position == GRP1
      @bl.old_value = @reg[ENABL] if position == GRP1
      @p1.old_value = @reg[GRP1]  if position == GRP0
      @latch_level.fill(true) if position == VBLANK && value[6] == 1
    end

    private

    def vertical_blank?
      @reg[VBLANK][1] != 0
    end

    def vertical_sync?
      @reg[VSYNC][1] != 0
    end

    def intialize_scanline
      @cpu.halted = false
      @late_reset_hblank = false
    end

    def wait_horizontal_blank
      @scanline_stage = :hblank
      HORIZONTAL_BLANK_CLK_COUNT.times { |color_clock| sync_2600_with color_clock }
    end

    def draw_scanline
      scanline = Array.new(160, 0)
      VISIBLE_CLK_COUNT.times do |pixel|
        @scanline_stage = @late_reset_hblank && pixel < 8 ? :late_hblank : :visible

        update_collision_flags
        sync_2600_with pixel + HORIZONTAL_BLANK_CLK_COUNT

        scanline[pixel] = topmost_pixel if @scanline_stage == :visible && !vertical_blank?

      end
      scanline
    end

    def topmost_pixel
      if @reg[CTRLPF][2].zero?
        @p0.pixel || @m0.pixel || @p1.pixel || @m1.pixel || @bl.pixel || @pf.pixel || @reg[COLUBK]
      else
        @pf.pixel || @bl.pixel || @p0.pixel || @m0.pixel || @p1.pixel || @m1.pixel || @reg[COLUBK]
      end
    end

    BIT_6 = 0b01000000
    BIT_7 = 0b10000000

    def update_collision_flags
      @reg[CXM0P]  |= BIT_6 if @m0.pixel && @p0.pixel
      @reg[CXM0P]  |= BIT_7 if @m0.pixel && @p1.pixel
      @reg[CXM1P]  |= BIT_6 if @m1.pixel && @p1.pixel
      @reg[CXM1P]  |= BIT_7 if @m1.pixel && @p0.pixel
      @reg[CXP0FB] |= BIT_6 if @p0.pixel && @bl.pixel
      @reg[CXP0FB] |= BIT_7 if @p0.pixel && @pf.pixel
      @reg[CXP1FB] |= BIT_6 if @p1.pixel && @bl.pixel
      @reg[CXP1FB] |= BIT_7 if @p1.pixel && @pf.pixel
      @reg[CXM0FB] |= BIT_6 if @m0.pixel && @bl.pixel
      @reg[CXM0FB] |= BIT_7 if @m0.pixel && @pf.pixel
      @reg[CXM1FB] |= BIT_6 if @m1.pixel && @bl.pixel
      @reg[CXM1FB] |= BIT_7 if @m1.pixel && @pf.pixel
      # c-c-c-combo breaker: bit 6 of CXLBPF is unused
      @reg[CXBLPF] |= BIT_7 if @bl.pixel && @pf.pixel
      @reg[CXPPMM] |= BIT_6 if @m0.pixel && @m1.pixel
      @reg[CXPPMM] |= BIT_7 if @p0.pixel && @p1.pixel
    end

    # All Atari chips use the same crystal for their clocks (with RIOT and
    # CPU running at 1/3 of TIA speed).
    #
    # Since the emulator's "main loop" is based on TIA#scanline, we'll "tick"
    # the other chips here

    def sync_2600_with(color_clock)
      riot.tick if color_clock % 3 == 0
      @graphics.each &:tick
      cpu.tick if color_clock % 3 == 2
    end

    # INPTx (I/O ports) helpers

    def value_for_port(number)
      return 0x00 if grounded_port?(number)
      level =   @port_level[number]
      level &&= @latch_level[number] if latched_port?(number)
      level ? 0x80 : 0x00
    end

    def grounded_port?(number)
      @reg[VBLANK][7] == 1 && number <= 3
    end

    def latched_port?(number)
      @reg[VBLANK][6] == 1 && number >= 4
    end
  end
end


