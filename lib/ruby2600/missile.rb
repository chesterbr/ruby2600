module Ruby2600
  class Missile < MovableObject
    include Constants

    def initialize(tia_registers, missile_number)
      super()
      @NUSIZn = missile_number.zero? ? NUSIZ0 : NUSIZ1
      @COLUPn = missile_number.zero? ? COLUP0 : COLUP1
      @ENAMn  = missile_number.zero? ? ENAM0  : ENAM1
      @tia = tia_registers
    end

    def pixel
    	update_pixel_bit
    	tick      
    	@tia[@COLUPn] if @pixel_bit == 1
   	end   

    def update_pixel_bit
      if @grp_bit
        if (0..7).include?(@grp_bit)
          @pixel_bit = @tia[@ENAMn][1]
          @bit_copies_written += 1
          if @bit_copies_written == missile_size
            @bit_copies_written = 0
            @grp_bit += 1
          end
        else
          @grp_bit += 1
        end
        @grp_bit = nil if @grp_bit > 0
      else
        @pixel_bit = nil
      end
    end

    def missile_size
    	2 ** (@tia[@NUSIZn][5] * 2 + @tia[@NUSIZn][4])
    end

    def on_counter_change
      if (value == 39) ||
         (value ==  3 && [0b001, 0b011].include?(@tia[@NUSIZn])) ||
         (value ==  7 && [0b010, 0b011, 0b110].include?(@tia[@NUSIZn])) ||
         (value == 15 && [0b100, 0b110].include?(@tia[@NUSIZn]))
        @grp_bit = -4
        @bit_copies_written = 0
      end
    end

  end
end