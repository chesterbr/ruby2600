module Ruby2600
  class FrameGenerator
    # A scanline "lasts" 228 "color clocks" (CLKs), of which 68
    # are the horizontal blank period, and 160 are visible pixels

    HORIZONTAL_BLANK_CLK_COUNT = 68
    VISIBLE_CLK_COUNT = 160

    def initialize(cpu, tia, riot)
      @cpu  = cpu
      @tia  = tia
      @riot = riot
    end

    def frame
      buffer = []
      scanline           while @tia.vertical_sync?   # VSync
      scanline           while @tia.vertical_blank?  # VBlank
      buffer << scanline until @tia.vertical_blank?  # Picture
      scanline           until @tia.vertical_sync?   # Overscan
      @frame_counter.add if @frame_counter
      buffer
    end

    # This scanline method will not store/return invisible scanlines
    # meaning you can call it and reset horizontal drawing counter if nil
    # FIXME review tests; Enduro errors out with it (maybe a clue to why it over-renders)
    def scanline
      intialize_scanline
      wait_horizontal_blank
      @beam_on ? visible_scanline : invisible_scanline
    end

    # Slightly more performatic frame (maybe more compatible? less?)
    # def frame
    #   buffer = []
    #   unless @beam_on
    #     s = scanline until @beam_on
    #   end
    #   buffer << scanline while @beam_on
    #   buffer.reject!(&:nil?)
    #   @frame_counter.add if @frame_counter
    #   buffer
    # end

    def intialize_scanline
      @cpu.halted = false
      @tia.late_reset_hblank = false
      @beam_on = !(@tia.vertical_blank? || @tia.vertical_sync?)
    end

    def wait_horizontal_blank
      @tia.scanline_stage = :hblank
      HORIZONTAL_BLANK_CLK_COUNT.times { |color_clock| sync_2600_with color_clock }
    end

    def visible_scanline
      scanline = Array.new(160, 0)
      VISIBLE_CLK_COUNT.times do |pixel|
        @tia.scanline_stage = @tia.late_reset_hblank && pixel < 8 ? :late_hblank : :visible

        @tia.update_collision_flags
        sync_2600_with pixel + HORIZONTAL_BLANK_CLK_COUNT

        scanline[pixel] = @tia.topmost_pixel if @tia.scanline_stage == :visible && !@tia.vertical_blank?
      end
      scanline
    end

    def invisible_scanline
      VISIBLE_CLK_COUNT.times do |pixel|
        @tia.scanline_stage = @tia.late_reset_hblank && pixel < 8 ? :late_hblank : :visible

        @tia.update_collision_flags
        sync_2600_with pixel + HORIZONTAL_BLANK_CLK_COUNT
      end
      nil
    end

    # All Atari chips use the same crystal for their clocks (with RIOT and
    # CPU running at 1/3 of TIA speed).

    def sync_2600_with(color_clock)
      @riot.tick if color_clock % 3 == 0
      @tia.tick
      @cpu.tick if color_clock % 3 == 2
    end

  end
end
