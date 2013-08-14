module Ruby2600
  class Graphic
    include Constants

    attr_accessor :counter

    # These parameters are specific to each type of graphic (player, missile, ball or playfield)
    class << self
      attr_accessor :graphic_delay, :graphic_size, :hmove_register, :color_register
    end

    def initialize(tia, graphic_number = 0)
      @tia = tia
      @graphic_number = graphic_number

      @counter = Counter.new
      @counter.on_change { on_counter_change }
    end

    def pixel(dont_tick_counter = false)
      unless dont_tick_counter
        update_graphic_bit_and_value
        counter.tick
      end
      reg(self.class.color_register) if @graphic_bit_value == 1
    end

    def start_hmove
      counter.start_hmove reg(self.class.hmove_register)
    end

    def apply_hmove
      applied = counter.apply_hmove reg(self.class.hmove_register)
      update_graphic_bit_and_value if applied
    end

    private

    # Adjusts the Value of a register for the current object
    # Ex.: reg(GRP0) will read GRP0 for P0, but GRP1 for P1;
    #      reg(HMM0) will read HMM0 for M0, but HMM1 for M1;
    def reg(register_name)
      @tia.reg[register_name + @graphic_number]
    end

    def update_graphic_bit_and_value
      if @graphic_bit
        if (0..7).include?(@graphic_bit)
          @graphic_bit_value = pixel_bit
          @bit_copies_written += 1
          if @bit_copies_written == size
            @bit_copies_written = 0
            @graphic_bit += 1
          end
        else
          @graphic_bit += 1
        end
        @graphic_bit = nil if @graphic_bit == self.class.graphic_size
      else
        @graphic_bit_value = nil
      end
    end

    def on_counter_change
      if should_draw_graphic? || should_draw_copy?
        @graphic_bit = -self.class.graphic_delay
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


