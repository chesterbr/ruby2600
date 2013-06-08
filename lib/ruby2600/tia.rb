module Ruby2600
  class TIA
    attr_accessor :cpu, :riot

    include Constants

    WBLANK_WIDTH = 68

    PLAYFIELD_ORDER = [[PF0, 4], [PF0, 5], [PF0, 6], [PF0, 7],
                       [PF1, 7], [PF1, 6], [PF1, 5], [PF1, 4], [PF1, 3], [PF1, 2], [PF1, 1], [PF1, 0],
                       [PF2, 0], [PF2, 1], [PF2, 2], [PF2, 3], [PF2, 4], [PF2, 5], [PF2, 6], [PF2, 7]]

    def initialize
      @reg = Array.new(32) { rand(256) }
      @cpu_credits = 0
    end

    def [](position)

    end

    def []=(position, value)
      @reg[position] = value
    end

    # A scanline "lasts" 228 "color clocks", of which 68 (WBLANK_WIDTH) are
    # the initial blank period, and each of the remaining 160 is a pixel

    def scanline
      reset_beam
      0.upto 227 do |color_clock|
        sync_cpu_with color_clock
        if color_clock >= WBLANK_WIDTH
          @pixel = color_clock - WBLANK_WIDTH
          unless vertical_blank?
            @scanline[@pixel] = pf_bit_set? ? pf_color : @reg[COLUBK]
          end
        end
      end
      @scanline
    end

    def frame
      buffer = []
      scanline while vertical_sync?
      buffer << scanline until vertical_sync?
      buffer
    end

    private

    def reset_beam
      reset_cpu_sync
      @scanline = Array.new(160, 0)
    end

    # The 2600 hardware wiring ensures that we have three color clocks
    # for each CPU clock, but "freezes" the CPU if WSYNC is set on TIA.
    #
    # To keep them in sync, we'll compute a "credit" for each color
    # clock, and "use" this credit when we have any of it

    def sync_cpu_with(color_clock)
      riot.pulse if color_clock % 3 == 0
      return if @reg[WSYNC]
      @cpu_credits += 1 if color_clock % 3 == 0
      @cpu_credits -= @cpu.step while @cpu_credits > 0
    end

    def reset_cpu_sync
      @cpu_credits = 0 if @reg[WSYNC]
      @reg[WSYNC] = nil
    end

    def vertical_blank?
      @reg[VBLANK] & 0b00000010 != 0
    end

    def vertical_sync?
      @reg[VSYNC] & 0b00000010 != 0
    end

    # Playfield

    def pf_bit_set?
      pf_pixel = (@pixel / 4) % 20
      pf_pixel = 19 - pf_pixel if reflect_current_side?
      register, bit = PLAYFIELD_ORDER[pf_pixel]
      @reg[register][bit] == 1
    end

    def reflect_current_side?
      @reg[CTRLPF][0] == 1 && @pixel > 79
    end

    def pf_color
      @reg[score_mode? ? COLUP0 + @pixel / 80 : COLUPF]
    end

    def score_mode?
      @reg[CTRLPF][1] == 1
    end

  end
end


