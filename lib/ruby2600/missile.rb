module Ruby2600
  class Missile < MovableObject

    @graphic_delay = 4

    def pixel
    	update_pixel_bit
    	tick      
    	@reg[COLUP0 + @n] if @pixel_bit == 1
   	end   

    def update_pixel_bit
      if @grp_bit
        if (0..7).include?(@grp_bit)
          @pixel_bit = @reg[ENAM0 + @n][1]
          @bit_copies_written += 1
          if @bit_copies_written == size
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

    def size
    	2 ** (@reg[NUSIZ0 + @n][5] * 2 + @reg[NUSIZ0 + @n][4])
    end
  end
end