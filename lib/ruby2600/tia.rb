module Ruby2600
  class TIA
    attr_accessor :cpu, :riot, :scanline_stage, :late_reset_hblank
    attr_reader :reg

    include Constants

    def initialize
      # Real 2600 starts with random values (and Stella comments warn
      # about games that crash if we start with all zeros)
      @reg = Array.new(64) { rand(256) }

      @p0 = Player.new(self, 0)
      @p1 = Player.new(self, 1)
      @m0 = Missile.new(self, 0)
      @m1 = Missile.new(self, 1)
      @bl = Ball.new(self)
      @pf = Playfield.new(self)

      @port_level = Array.new(6, false)
      @latch_level = Array.new(6, true)
    end

    def set_port_level(number, level)
      @port_level[number] = (level == :high)
      @latch_level[number] = false if level == :low
    end

    # Accessors for games (other classes should use :reg to avoid side effects)

    def [](position)
      case position
      when CXM0P..CXPPMM then @reg[position]
      when INPT0..INPT5  then value_for_port(position - INPT0)
      end
    end

    def []=(position, value)
      case position
      when RESP0
        @p0.reset
      when RESP1
        @p1.reset
      when RESM0
        @m0.reset
      when RESM1
        @m1.reset
      when RESBL
        @bl.reset
      when RESMP0
        @m0.reset_to @p0
      when RESMP1
        @m1.reset_to @p1
      when HMOVE
        @late_reset_hblank = true
        @p0.start_hmove
        @p1.start_hmove
        @m0.start_hmove
        @m1.start_hmove
        @bl.start_hmove
      when HMCLR
        @reg[HMP0] = @reg[HMP1] = @reg[HMM0] = @reg[HMM1] = @reg[HMBL] = 0
      when CXCLR
        @reg[CXM0P] = @reg[CXM1P] = @reg[CXP0FB] = @reg[CXP1FB] = @reg[CXM0FB] = @reg[CXM1FB] = @reg[CXBLPF] = @reg[CXPPMM] = 0
      when WSYNC
        @cpu.halted = true
      when NUSIZ0, NUSIZ1, CTRLPF
        @reg[position] = six_bit_value(value)
      when VSYNC..VDELBL
        @reg[position] = value
      end
      @p0.old_value = @reg[GRP0]  if position == GRP1
      @bl.old_value = @reg[ENABL] if position == GRP1
      @p1.old_value = @reg[GRP1]  if position == GRP0
      @latch_level.fill(true) if position == VBLANK && value[6] == 1
    end

    def tick
      @p0.tick
      @p1.tick
      @m0.tick
      @m1.tick
      @bl.tick
      @pf.tick
    end

    def vertical_blank?
      @reg[VBLANK][1] != 0
    end

    def vertical_sync?
      @reg[VSYNC][1] != 0
    end

    def topmost_pixel
      if @reg[CTRLPF][2].zero?
        @p0.pixel || @m0.pixel || @p1.pixel || @m1.pixel || @bl.pixel || @pf.pixel || @reg[COLUBK]
      else
        @pf.pixel || @bl.pixel || @p0.pixel || @m0.pixel || @p1.pixel || @m1.pixel || @reg[COLUBK]
      end
    end

    BIT_6 = 0b01000000
    BIT_7 = 0b10000000

    def update_collision_flags
      # m0_pixel = @m0.pixel
      # m1_pixel = @m1.pixel
      # p0_pixel = @p0.pixel
      # p1_pixel = @p1.pixel
      # bl_pixel = @bl.pixel
      # pf_pixel = @pf.pixel
      # @reg[CXM0P] |= BIT_6 if m0_pixel && p0_pixel
      # @reg[CXM0P] |= BIT_7 if m0_pixel && p1_pixel
      # @reg[CXM1P] |= BIT_6 if m1_pixel && p1_pixel
      # @reg[CXM1P] |= BIT_7 if m1_pixel && p0_pixel
      # @reg[CXP0FB] |= BIT_6 if p0_pixel && bl_pixel
      # @reg[CXP0FB] |= BIT_7 if p0_pixel && pf_pixel
      # @reg[CXP1FB] |= BIT_6 if p1_pixel && bl_pixel
      # @reg[CXP1FB] |= BIT_7 if p1_pixel && pf_pixel
      # @reg[CXM0FB] |= BIT_6 if m0_pixel && bl_pixel
      # @reg[CXM0FB] |= BIT_7 if m0_pixel && pf_pixel
      # @reg[CXM1FB] |= BIT_6 if m1_pixel && bl_pixel
      # @reg[CXM1FB] |= BIT_7 if m1_pixel && pf_pixel
      # # c-c-c-combo breaker: bit 6 of CXLBPF is unused
      # @reg[CXBLPF] |= BIT_7 if bl_pixel && pf_pixel
      # @reg[CXPPMM] |= BIT_6 if m0_pixel && m1_pixel
      # @reg[CXPPMM] |= BIT_7 if p0_pixel && p1_pixel
    end

    private

    # INPTx (I/O ports) helpers

    def value_for_port(number)
      return 0x00 if grounded_port?(number)
      level =   @port_level[number]
      level &&= @latch_level[number] if latched_port?(number)
      level ? 0x80 : 0x00
    end

    def grounded_port?(number)
      @reg[VBLANK][7] == 1 && number <= 3
    end

    def latched_port?(number)
      @reg[VBLANK][6] == 1 && number >= 4
    end

    def six_bit_value(number)
      number & 0b111111
    end
  end
end


