module Ruby2600
  class Player < MovableObject
    attr_accessor :old_GRPn

    @graphic_delay = 5

    def pixel
      update_pixel_bit
      tick      
      @reg[COLUP0 + @n] if @pixel_bit == 1
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
      return 8 unless @reg[HMP0 + @n]
      signed = @reg[HMP0 + @n] >> 4
      signed >= 8 ? signed - 8 : signed + 8
    end

    private

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
      result = @reg[VDELP0 + @n] && @reg[VDELP0 + @n][0] == 1 ? @old_GRPn : @reg[GRP0 + @n]
      @reg[REFP0 + @n] && @reg[REFP0 + @n][3] == 1 ? reflect(result) : result
    end

    def reflect(bits)
      (0..7).inject(0) { |value, n| value + (bits[n] << (7 - n)) }
    end

    def player_size
      case @reg[NUSIZ0 + @n]
      when 0b101 then 2
      when 0b111 then 4
      else 1
      end
    end
  end
end

