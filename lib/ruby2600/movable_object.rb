module Ruby2600
  class MovableObject
    include Constants

    # Value used by player/balls when vertical delay (VDELP0/VDELP1/VDELBL) is set
    # GRP1 write triggers copy of GRP0/ENABL to old_value, GRP0 write does same for GRP1
    attr_accessor :old_value 

    # Movable objects on TIA keep internal counters with behaviour
    # described in  http://www.atarihq.com/danb/files/TIA_HW_Notes.txt

    COUNTER_PERIOD = 40       # Internal counter value ranges from 0-39
    COUNTER_DIVIDER = 4       # It increments every 4 ticks (1/4 of TIA speed)
    COUNTER_RESET_VALUE = 39  # See URL above 
    
    COUNTER_MAX = COUNTER_PERIOD * COUNTER_DIVIDER

    class << self
      attr_accessor :graphic_delay, :graphic_size, :hmove_register, :color_register

      @graphic_size = @graphic_delay = @hmove_register = @color_register = 0
    end

    def initialize(tia_registers, object_number = 0)
      @tia_registers = tia_registers
      @object_number = object_number
      @counter_inner_value = rand(COUNTER_MAX)
      @old_value = rand(256)
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
      reg(self.class.color_register) if @pixel_bit == 1
    end

    def start_hmove
      @hmove_counter = 0
      @movement_required = true if hm_value != 0
    end

    def apply_hmove
      return unless @movement_required
      tick
      @hmove_counter += 1
      @movement_required = false if @hmove_counter == hm_value
    end

    private

    # Value of a register for the current object
    # Ex.: reg(GRP0) will read GRP0 for P0, but GRP1 for P1;
    #      reg(HMM0) will read HMM0 for M0, but HMM1 for M1;
    def reg(register_name)
      @tia_registers[register_name + @object_number]
    end

    def hm_value
      hm = reg(self.class.hmove_register)
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
      if (value == COUNTER_RESET_VALUE) || should_draw_copy?
        @grp_bit = -self.class.graphic_delay
        @bit_copies_written = 0
      end
    end

    def should_draw_copy?
      (value ==  3 && [0b001, 0b011].include?(reg(NUSIZ0))) ||
      (value ==  7 && [0b010, 0b011, 0b110].include?(reg(NUSIZ0))) ||
      (value == 15 && [0b100, 0b110].include?(reg(NUSIZ0)))
    end
  end
end


