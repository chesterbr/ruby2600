module Ruby2600
  class TIA
    include Constants
    attr_accessor :pf0, :pf1, :pf2, :colubk, :colupf

    def initialize
      @reg = Array(32)
    end

    def [](position)

    end

    def []=(position, value)
      @reg[position] = value
    end

    def scanline
      Array.new(160, @reg[PF0] == 0 ? @reg[COLUBK] : @reg[COLUPF])
    end
  end
end


