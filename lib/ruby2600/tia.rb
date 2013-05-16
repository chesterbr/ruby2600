module Ruby2600
  class TIA
    attr_accessor :cpu

    include Constants

    def initialize
      @reg = Array.new(32)
      @scanline = Array.new(160)
      @cpu_credits = 0
    end

    def [](position)

    end

    def []=(position, value)
      @reg[position] = value
    end

    def scanline
      pf_reset
      (0..227).each do |tia_clock|
        @cpu_credits += 1 if tia_clock % 3 == 0
        @cpu_credits -= @cpu.step if @cpu_credits > 0 #&& !@cpu_suspended # may be suspended by sta wsync
        if tia_clock > 67
          @pixel = tia_clock - 68
          @scanline[@pixel] = pf_bit.nonzero? ? @reg[COLUPF] : @reg[COLUBK]
          pf_fetch
        end
      end
      @scanline
    end

    private

    # Playfield

    def pf_reset
      @pf_reg = PF0
      @pf_bit = 4
      @pf_direction = 1
    end

    def pf_bit
      @reg[@pf_reg][@pf_bit]
    end

    def pf_fetch
      if @pixel % 80 % 4 == 3
        @pf_bit += @pf_direction
        pf_flip_direction_and_register if @pf_bit == 8 || @pf_bit == -1
        pf_reset if @pf_reg > PF2
      end
    end

    def pf_flip_direction_and_register
      @pf_direction = -@pf_direction
      @pf_bit += @pf_direction
      @pf_reg += 1
    end
  end
end


