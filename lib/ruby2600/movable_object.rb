module Ruby2600
  class MovableObject

    # Movable objects on TIA keep internal counters with behaviour
    # described in  http://www.atarihq.com/danb/files/TIA_HW_Notes.txt

    COUNTER_PERIOD = 40       # Internal counter value ranges from 0-39
    COUNTER_DIVIDER = 4       # It increments every 4 ticks (1/4 of TIA speed)
    COUNTER_RESET_VALUE = 39  # See URL above 
    
    COUNTER_MAX = COUNTER_PERIOD * COUNTER_DIVIDER

    def initialize
      @counter_inner_value = rand(COUNTER_MAX)
    end

    def strobe
      @counter_inner_value = COUNTER_RESET_VALUE * COUNTER_DIVIDER
    end

    def value
      @counter_inner_value / COUNTER_DIVIDER
    end

    def value=(x)
      @counter_inner_value = x * COUNTER_DIVIDER
    end

    def tick
      old_value = value
      @counter_inner_value = (@counter_inner_value + 1) % COUNTER_MAX
      on_counter_change if value != old_value
    end

    private

    def on_counter_change
      # Objects to trigger their "drawing circuits" by overriding this
    end

    def nibble_to_decimal(signed_byte)
      [0, 1, 2, 3, 4, 5, 6, 7, -8, -7, -6, -5, -4, -3, -2, -1][signed_byte & 0b1111]
    end
  end
end


