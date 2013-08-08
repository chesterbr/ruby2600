module Ruby2600
  class MovableObject
    include Constants

    # Value used by player/balls when vertical delay (VDELP0/VDELP1/VDELBL) is set
    # GRP1 write triggers copy of GRP0/ENABL to old_value, GRP0 write does same for GRP1
    attr_accessor :old_value, :counter

    class << self
      attr_accessor :graphic_delay, :graphic_size, :hmove_register, :color_register

      @graphic_size = @graphic_delay = @hmove_register = @color_register = 0
    end

    def initialize(tia, object_number = 0)
      @tia = tia
      @object_number = object_number
      @old_value = rand(256)

      @counter = Counter.new
      @counter.on_change { on_counter_change }
    end

    def pixel(dont_tick_counter = false)
      unless dont_tick_counter
        update_pixel_bit
        counter.tick
      end
      reg(self.class.color_register) if @pixel_bit == 1
    end

    def start_hmove
      counter.start_hmove reg(self.class.hmove_register)
    end

    def apply_hmove
      counter.apply_hmove reg(self.class.hmove_register)
    end

    private

    # Value of a register for the current object
    # Ex.: reg(GRP0) will read GRP0 for P0, but GRP1 for P1;
    #      reg(HMM0) will read HMM0 for M0, but HMM1 for M1;
    def reg(register_name)
      @tia.reg[register_name + @object_number]
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
      if should_draw_graphic? || should_draw_copy?
        @grp_bit = -self.class.graphic_delay
        @bit_copies_written = 0
      end
    end

    def should_draw_graphic?
      counter.value == 39
    end

    def should_draw_copy?
      nusiz_bits = reg(NUSIZ0) & 0b111
      (counter.value ==  3 && [0b001, 0b011].include?(nusiz_bits)) ||
      (counter.value ==  7 && [0b010, 0b011, 0b110].include?(nusiz_bits)) ||
      (counter.value == 15 && [0b100, 0b110].include?(nusiz_bits))
    end
  end
end


