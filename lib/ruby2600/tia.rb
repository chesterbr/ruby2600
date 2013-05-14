module Ruby2600
  class Tia
    attr_accessor :pf0, :pf1, :pf2, :colubk, :colupf

    def scanline
      Array.new(160, pf0 == 0 ? colubk : colupf)
    end
  end
end


