module Ruby2600
  class Player < MovableObject
    include Constants

    attr_accessor :old_GRPn

    def initialize(tia_registers, player_number)
      super()
      @NUSIZn = player_number.zero? ? NUSIZ0 : NUSIZ1
      @COLUPn = player_number.zero? ? COLUP0 : COLUP1
      @GRPn   = player_number.zero? ? GRP0   : GRP1
      @VDELPn = player_number.zero? ? VDELP0 : VDELP1
      @REFPn  = player_number.zero? ? REFP0  : REFP1
      @HMPn   = player_number.zero? ? HMP0   : HMP1
      @tia = tia_registers
    end

    def pixel
      update_pixel_bit
      tick      
      @tia[@COLUPn] if @pixel_bit == 1
    end

    # FIXME might call reset?
    def strobe
      reset
    end

    def start_hmove
      @hmove_counter = 0
      @movement_required = true if moves_to_apply_for_HMPn != 0
    end

    def apply_hmove
      return unless @movement_required
      tick
      @hmove_counter += 1
      @movement_required = false if @hmove_counter == moves_to_apply_for_HMPn
    end

    def moves_to_apply_for_HMPn
      return 8 unless @tia[@HMPn]
      signed = @tia[@HMPn] >> 4
      signed >= 8 ? signed - 8 : signed + 8
    end

    private

    def on_counter_change
      if (value == 39) ||
         (value ==  3 && [0b001, 0b011].include?(@tia[@NUSIZn])) ||
         (value ==  7 && [0b010, 0b011, 0b110].include?(@tia[@NUSIZn])) ||
         (value == 15 && [0b100, 0b110].include?(@tia[@NUSIZn]))
        @grp_bit = -5
        @bit_copies_written = 0
      end
    end

    def update_pixel_bit
      if @grp_bit
        if (0..7).include?(@grp_bit)
          @pixel_bit = grp[7 - @grp_bit] 
          @bit_copies_written += 1
          if @bit_copies_written == player_size
            @bit_copies_written = 0
            @grp_bit += 1
          end
        else
          @grp_bit += 1
        end
        @grp_bit = nil if @grp_bit > 7
      else
        @pixel_bit = nil
      end
    end

    def grp
      result = @tia[@VDELPn] && @tia[@VDELPn][0] == 1 ? @old_GRPn : @tia[@GRPn]
      @tia[@REFPn] && @tia[@REFPn][3] == 1 ? reflect(result) : result
    end

    def reflect(bits)
      (0..7).inject(0) { |value, n| value + (bits[n] << (7 - n)) }
    end

    def player_size
      case @tia[@NUSIZn]
      when 0b101 then 2
      when 0b111 then 4
      else 1
      end
    end
  end
end

