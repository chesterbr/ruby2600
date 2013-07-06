module Ruby2600
  # Movable objects on TIA use counters that go from 0 to 39, but run at 1/4
  # of the TIA speed. See http://www.atarihq.com/danb/files/TIA_HW_Notes.txt
  # FIXME review test coverage due to hmove spike
  class TIACounter
    PERIOD = 40
    CLKS_PER_COUNT = 4
    MAX_VALUE = PERIOD * CLKS_PER_COUNT - 1

    def initialize
      @internal_value = rand(MAX_VALUE)
    end

    def reset
      # FIXME 35 * TIA_CLKS_PER_COUNT works for Pitfall ball; may be an
      # artifact of lack other implementations
      @internal_value = 0
    end

    def value
      @internal_value / CLKS_PER_COUNT
    end

    # FIXME this is for tests only (to avoid tests peeking into internals), should stay?
    def value=(x)
      @internal_value = x * CLKS_PER_COUNT
    end

    def tick
      old_value = value
      @internal_value += 1
      @internal_value = 0 if @internal_value == 160
      @on_change.call(value) if @on_change && value != old_value
    end

    def on_change(&block)
      @on_change = block
    end

    private

    def internal_value_add(value)
      @internal_value += value
      @internal_value -= 160 while @internal_value >= MAX_VALUE
      @internal_value += 160 while @internal_value < 0
    end

    def nibble_to_decimal(signed_nibble)
      absolute = signed_nibble & 0b0111
      signal   = signed_nibble[3] * 2 - 1
      absolute * signal
    end
>>>>>>> 663edfa... Removing magic numbers
  end
end


