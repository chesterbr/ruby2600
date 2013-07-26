module Ruby2600
  class MovableObject
    include Constants

    # Movable objects on TIA keep internal counters with behaviour
    # described in  http://www.atarihq.com/danb/files/TIA_HW_Notes.txt

    COUNTER_PERIOD = 40       # Internal counter value ranges from 0-39
    COUNTER_DIVIDER = 4       # It increments every 4 ticks (1/4 of TIA speed)
    COUNTER_RESET_VALUE = 39  # See URL above 
    
    COUNTER_MAX = COUNTER_PERIOD * COUNTER_DIVIDER

    class << self
      attr_accessor :graphic_delay, :graphic_size, :hmove_register

      @graphic_size = @graphic_delay = @hmove_register = 0
    end

    def initialize(tia_registers = nil, object_number = 0)
      @counter_inner_value = rand(COUNTER_MAX)

      # These will help us use the correct TIA registers for Pn/Mn
      # Ex.: for Player 1, @reg[NUSIZ0+@n] will be the value of NUSIZ1
      @reg = tia_registers
      @n   = object_number
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

    def pixel
      update_pixel_bit
      tick      
      @reg[COLUP0 + @n] if @pixel_bit == 1
    end

    def start_hmove
      @hmove_counter = 0
      @movement_required = true if HM_value != 0
    end

    def apply_hmove
      return unless @movement_required
      tick
      @hmove_counter += 1
      @movement_required = false if @hmove_counter == HM_value
    end

    private

    def HM_value
      hm = @reg[self.class.hmove_register + @n]
      return 8 unless hm
      signed = hm >> 4
      signed >= 8 ? signed - 8 : signed + 8
    end

    def update_pixel_bit
      if @grp_bit
        if (0..7).include?(@grp_bit)
          @pixel_bit = pixel_bit
          @bit_copies_written += 1
          if @bit_copies_written == size
            @bit_copies_written = 0
            @grp_bit += 1
          end
        else
          @grp_bit += 1
        end
        @grp_bit = nil if @grp_bit == self.class.graphic_size
      else
        @pixel_bit = nil
      end
    end

    def on_counter_change
      if (value == 39) ||
         (value ==  3 && [0b001, 0b011].include?(@reg[NUSIZ0 + @n])) ||
         (value ==  7 && [0b010, 0b011, 0b110].include?(@reg[NUSIZ0 + @n])) ||
         (value == 15 && [0b100, 0b110].include?(@reg[NUSIZ0 + @n]))
        @grp_bit = -self.class.graphic_delay
        @bit_copies_written = 0
      end
    end
  end
end


