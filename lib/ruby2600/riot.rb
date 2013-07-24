module Ruby2600
  class RIOT
    include Constants

    def initialize
      @ram = Array.new(128)
      self[T1024T] = rand(256) # FIXME Stella says H.E.R.O. hangs if it is zero, check it out
      @portA = @portB = @swcha = @swchb = @swacnt = @swbcnt = 0
    end

    def [](address)
      case address
      when 0x00..0x7F then @ram[address]
      when INTIM      then @timer
      when INSTAT     then read_timer_flags
      when SWCHA      then (@swcha & @swacnt) | (@portA & (@swacnt ^ 0xFF))
      when SWCHB      then (@swchb & @swbcnt) | (@portB & (@swbcnt ^ 0xFF))
      end
    end

    def []=(address, value)
      case address
      when 0x00..0x7F then @ram[address] = value
      when TIM1T      then initialize_timer(value, 1)
      when TIM8T      then initialize_timer(value, 8)
      when TIM64T     then initialize_timer(value, 64)
      when T1024T     then initialize_timer(value, 1024)
      when SWCHA      then @swcha  = value
      when SWACNT     then @swacnt = value
      when SWCHB      then @swchb  = value
      when SWBCNT     then @swbcnt = value
      end
    end

    def tick
      @cycle_count -= 1
      if @cycle_count == 0
        decrement_timer
      end
    end

    def portA=(value)
      @portA = value
    end

    def portB=(value)
      @portB = value
    end

    private

    def initialize_timer(value, resolution)
      @timer_flags = 0
      @timer = value
      @resolution = resolution
      decrement_timer
    end

    def decrement_timer
      @timer -= 1
      underflow if @timer < 0
      reset_cycle_count
    end

    def underflow
      @timer_flags = 0b11000000
      @timer = 0xFF
      @resolution = 1
    end

    def reset_cycle_count
      @cycle_count = @resolution
    end

    def read_timer_flags
      instat = @timer_flags
      @timer_flags &= 0b10111111
      instat
    end

  end
end
