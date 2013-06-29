module Ruby2600
  # Movable objects are implemented internally on TIA using counters that go
  # from 0 to 39, but only increment after 4 color clocks (to match the 160
  # pixels of a scanline)
  # See http://www.atarihq.com/danb/files/TIA_HW_Notes.txt
  class TIACounter
    def initialize
      @internal_value = rand(160)
    end

    def reset
      @internal_value = 0
    end

    def value
      @internal_value / 4
    end

    def value=(x)
      @internal_value = x * 4
    end

    def tick
      @internal_value += 1
      @internal_value = 0 if @internal_value == 160
    end
  end
end


