# Movable objects on TIA keep internal counters, which this class implements
# as described in http://www.atarihq.com/danb/files/TIA_HW_Notes.txt
module Ruby2600
  class Counter
    attr_accessor :notify_change_on_strobe

    COUNTER_PERIOD = 40       # Internal counter value ranges from 0-39
    COUNTER_DIVIDER = 4       # It increments every 4 ticks (1/4 of TIA speed)
    COUNTER_RESET_VALUE = 39  # See URL above

    COUNTER_MAX = COUNTER_PERIOD * COUNTER_DIVIDER

    def initialize
      @counter_inner_value = rand(COUNTER_MAX)
      @notify_change_on_strobe = false
    end

    def strobe
      @counter_inner_value = COUNTER_RESET_VALUE * COUNTER_DIVIDER
      @change_listener.call if @notify_change_on_strobe
    end

    def value
      @counter_inner_value / COUNTER_DIVIDER
    end

    def value=(x)
      @counter_inner_value = x * COUNTER_DIVIDER
    end

    def on_change(&block)
      @change_listener = block
    end

    def reset_to(other_counter)
      @counter_inner_value = other_counter.instance_variable_get(:@counter_inner_value)
    end

    def tick
      old_value = value
      @counter_inner_value = (@counter_inner_value + 1) % COUNTER_MAX
      @change_listener.call if @change_listener && value != old_value
    end
  end
end