# Movable objects on TIA keep internal counters, which this class implements
# as described in http://www.atarihq.com/danb/files/TIA_HW_Notes.txt
module Ruby2600
  class Counter
    attr_accessor :notify_change_on_strobe

    PERIOD = 40       # "Visible" counter value ranges from 0-39...
    DIVIDER = 4       # ...incrementing every 4 "ticks" from TIA (1/4 of TIA clock)
    RESET_VALUE = 39  # Value set when the TIA RESxx position is strobed

    INTERNAL_PERIOD = PERIOD * DIVIDER

    def initialize
      @internal_value = rand(INTERNAL_PERIOD)
      @notify_change_on_strobe = false
    end

    def value
      @internal_value / DIVIDER
    end

    def value=(x)
      @internal_value = x * DIVIDER
    end

    # TIA graphic circuits are triggered when the visible counter value changes, so
    # graphics should provide this listener. The ball will also trigger it on strobe
    # (and that is why it draws immediately and not on the next scanline)

    def on_change(&block)
      @change_listener = block
    end

    def tick
      old_value = value
      @internal_value = (@internal_value + 1) % INTERNAL_PERIOD
      @change_listener.call if @change_listener && value != old_value
    end

    def strobe
      @internal_value = RESET_VALUE * DIVIDER
      @change_listener.call if @notify_change_on_strobe
    end

    def reset_to(other_counter)
      @internal_value = other_counter.instance_variable_get(:@internal_value)
    end

    # Horizontal movement (HMOV) is implemented by extending the horizontal blank
    # by 8 pixels. That shortens the visible scanline to 152 pixels (producing the
    # "comb effect" on the left side) and pushes all graphics 8 pixels to the right...

    def start_hmove(register_value)
      @ticks_added = 0
      @movement_required = !ticks_to_add(register_value).zero?
    end

    # ...but then TIA stuffs each counter with an extra cycle, counting those until
    # it reaches the current value for the HMMxx register for that graphic). Each
    # extra tick means pushing the graphic 1 pixel to the left, so the final movement
    # ends up being something betwen 8 pixels to the right (0 extra ticks) and
    # 7 pixels to the left (15 extra ticks)

    def apply_hmove(register_value)
      return unless @movement_required
      tick
      @ticks_added += 1
      @movement_required = false if @ticks_added == ticks_to_add(register_value)
    end

    private

    def ticks_to_add(register_value)
      nibble = register_value >> 4
      nibble < 8 ? nibble + 8 : nibble - 8
    end
  end
end