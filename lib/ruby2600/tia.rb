module Ruby2600
  class TIA
    include Constants

    def initialize
      @reg = Array.new(32)
      @scanline = Array.new(160)
    end

    def [](position)

    end

    def []=(position, value)
      @reg[position] = value
    end

    def scanline
      pf_reset
      (0..159).each do |pixel|
        @pixel = pixel
        @scanline[pixel] = pf_bit.nonzero? ? @reg[COLUPF] : @reg[COLUBK]
        pf_fetch
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


