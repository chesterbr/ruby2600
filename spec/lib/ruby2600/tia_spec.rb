require 'spec_helper'

describe Ruby2600::TIA do

  subject(:tia) do
    tia = Ruby2600::TIA.new
    tia.cpu = double('cpu', :tick => nil, :halted= => nil)
    tia.riot = double('riot', :tick => nil)

    # Make registers accessible (for easier testing)
    def tia.reg
      @reg
    end

    tia
  end

  def clear_tia_registers
    0x3F.downto(0) { |reg| tia[reg] = 0 }
  end

  describe '#initialize' do
    it 'initializes with random values on registers' do
      registers1 = Ruby2600::TIA.new.instance_variable_get(:@reg)
      registers2 = tia.instance_variable_get(:@reg)

      expect(registers1).not_to eq(registers2)
    end

    it "initializes with valid (byte-size) values on registers" do
      tia.instance_variable_get(:@reg).each do |register_value|
        expect(0..255).to cover register_value
      end
    end
  end

  describe '#topmost_pixel' do
    before do
      tia[COLUBK] = 0xBB
      tia[COLUPF] = 0xFF
      tia[PF0]    = 0xF0
      tia[PF1]    = 0xFF
      tia[PF2]    = 0xFF
    end

    context 'CTRLPF priority bit clear' do
      before { tia[CTRLPF] = rand(256) & 0b011 }

      it { expect(tia).to be_using_priority [:p0, :m0, :p1, :m1, :bl, :pf] }
    end

    context 'CTRLPF priority bit set' do
      before { tia[CTRLPF] = rand(256) | 0b100 }

      it { expect(tia).to be_using_priority [:pf, :bl, :p0, :m0, :p1, :m1] }
    end

    # This code tests that, for an ordered list of graphic objects,
    # the first one that generates color is the topmost_pixel
    # FIXME: the warning for the old syntax shows the smell of an overly complicated test
    class Ruby2600::TIA
      def using_priority?(enabled, disabled = [])
        # Makes color = order in list for enabled objects (and nil for disabled)
        enabled.count.times { |i| turn_on(enabled[i], i) }
        disabled.each { |p| turn_off(p) }
        # The first object (color = 0) should be the topmost...
        return false unless topmost_pixel == 0
        # ...and we disable it to recursively check the second, third, etc.
        first = enabled.shift
        using_priority?(enabled, disabled << first) if enabled.any?
        # Also: if all of them are disabled, the background color should be used
        turn_off first
        topmost_pixel == @reg[COLUBK]
      end

      def turn_on(object, color)
        instance_variable_get("@#{object}").stub(:pixel).and_return(color)
      end

      def turn_off(object)
        instance_variable_get("@#{object}").stub(:pixel).and_return(nil)
      end
    end
  end

  describe '#vertical_blank?' do
    context 'VBLANK bit set' do
      before { tia[VBLANK] = rand_with_bit(1, :set) }

      it { expect(tia.vertical_blank?).to be_truthy }
    end

    context 'VBLANK bit clear' do
      before { tia[VBLANK] = rand_with_bit(1, :clear) }

      it { expect(tia.vertical_blank?).to be_falsey }
    end
  end

  describe '#[]=' do
    [
      VSYNC, VBLANK, RSYNC, COLUP0, COLUP1, COLUPF,
      COLUBK, REFP0, REFP1, PF0, PF1, PF2, AUDC0, AUDC1, AUDF0,
      AUDF1, AUDV0, AUDV1, GRP0, GRP1, ENAM0, ENAM1, ENABL, HMP0, HMP1,
      HMM0, HMM1, HMBL, VDELP0, VDELP1, VDELBL
    ].each do |r|
      it "stores the value for #{r}" do
        value = rand(256)
        tia[r] = value

        expect(tia.reg[r]).to eq(value)
      end
    end

    # This registers have the bits 6, 7 protected from writing
    [
        NUSIZ0, NUSIZ1, CTRLPF
    ].each do |r|
      it "stores the value for #{r}" do
        value = rand(63)
        tia[r] = value

        expect(tia.reg[r]).to eq(value)
      end
    end

    [
      WSYNC, RESP0, RESP1, RESM0, RESM1, RESBL, HMOVE, HMCLR, CXCLR,
      CXM0P, CXM1P, CXP0FB, CXP1FB, CXM0FB, CXM1FB, CXBLPF, CXPPMM,
      INPT0, INPT1, INPT2, INPT3, INPT4, INPT5
    ].each do |r|
      it "does not store the value for #{r}" do
        value = rand(256)
        expect(tia.reg).not_to receive(:[]=).with(r, value)

        tia[r] = value
      end
    end
  end

  context 'positioning' do
    0.upto 1 do |n|
      describe "RESMP#{n}" do
        let(:player)  { tia.instance_variable_get "@p#{n}" }
        let(:missile) { tia.instance_variable_get "@m#{n}" }
        it "resets m#{n}'s counter to p#{n}'s when strobed" do
          expect(missile).to receive(:reset_to).with(player)

          tia[RESMP0 + n] = rand(256)
        end
      end
    end
  end


  context 'collisions' do
    describe 'CXCLR' do
      before do
        CXM0P.upto(CXPPMM) { |flag_reg| tia.reg[flag_reg] = rand(256) }
      end

      it 'resets flags when written' do
        tia[CXCLR] = 0

        expect(tia[CXM0P][6]).to eq(0)
        expect(tia[CXM0P][7]).to eq(0)
        expect(tia[CXM1P][6]).to eq(0)
        expect(tia[CXM1P][7]).to eq(0)
        expect(tia[CXP0FB][6]).to eq(0)
        expect(tia[CXP0FB][7]).to eq(0)
        expect(tia[CXP1FB][6]).to eq(0)
        expect(tia[CXP1FB][7]).to eq(0)
        expect(tia[CXM0FB][6]).to eq(0)
        expect(tia[CXM0FB][7]).to eq(0)
        expect(tia[CXM1FB][6]).to eq(0)
        expect(tia[CXM1FB][7]).to eq(0)
        # Bit 6 of CXBLPF is not used
        expect(tia[CXBLPF][7]).to eq(0)
        expect(tia[CXPPMM][6]).to eq(0)
        expect(tia[CXPPMM][7]).to eq(0)
      end
    end

    describe '#update_collision_flags' do
      it_does 'update collision register bit for objects', CXM0P,  6, :m0, :p0
      it_does 'update collision register bit for objects', CXM0P,  7, :m0, :p1
      it_does 'update collision register bit for objects', CXM1P,  6, :m1, :p1
      it_does 'update collision register bit for objects', CXM1P,  7, :m1, :p0
      it_does 'update collision register bit for objects', CXP0FB, 6, :p0, :bl
      it_does 'update collision register bit for objects', CXP0FB, 7, :p0, :pf
      it_does 'update collision register bit for objects', CXP1FB, 6, :p1, :bl
      it_does 'update collision register bit for objects', CXP1FB, 7, :p1, :pf
      it_does 'update collision register bit for objects', CXM0FB, 6, :m0, :bl
      it_does 'update collision register bit for objects', CXM0FB, 7, :m0, :pf
      it_does 'update collision register bit for objects', CXM1FB, 6, :m1, :bl
      it_does 'update collision register bit for objects', CXM1FB, 7, :m1, :pf
      # Bit 6 of CXBLPF is not used
      it_does 'update collision register bit for objects', CXBLPF, 7, :bl, :pf
      it_does 'update collision register bit for objects', CXPPMM, 6, :m0, :m1
      it_does 'update collision register bit for objects', CXPPMM, 7, :p0, :p1
    end
  end

  describe '#set_port_level / VBLANK register input control' do
    context 'normal mode' do
      before { tia[VBLANK] = 0 }

      0.upto(5) { |p| it_does 'reflect port input', p }
    end

    context 'latched mode' do
      before { tia[VBLANK] = 0b01000000 }

      0.upto(3) { |p| it_does 'reflect port input', p }
      4.upto(5) { |p| it_does 'latch port input', p}
    end

    context 'grounded mode' do
      before { tia[VBLANK] = 0b10000000 }

      0.upto(3) { |p| it_does 'dump port to ground', p }
      4.upto(5) { |p| it_does 'reflect port input', p }
    end

    context 'latched + grounded mode' do
      before { tia[VBLANK] = 0b11000000 }

      0.upto(3) { |p| it_does 'dump port to ground', p }
      4.upto(5) { |p| it_does 'latch port input', p}
    end
  end

  # The "ideal" NTSC frame has 259 scanlines (+3 of vsync, which we don't return),
  # but we should allow some leeway (we won't emulate "screen roll" that TVs do
  # with irregular frames)

  describe '#frame' do
    def build_frame(lines)
      @counter ||= -10 # Start on the "previous" frame
      @counter += 1
      case @counter
      when 0, lines + 3 then tia[VSYNC] = rand_with_bit(1, :set)   # Begin frame
      when 3            then tia[VSYNC] = rand_with_bit(1, :clear) # End frame
      end
      tia[WSYNC] = 255 # Finish scanline
    end

    258.upto(260).each do |lines|
      xit "generates a frame with #{lines} scanlines" do
        allow(tia.cpu).to receive(:tick) { build_frame(lines) }

        tia[VSYNC] = rand_with_bit 1, :clear
        tia.frame
        expect(tia.frame.size).to eq(lines)
      end
    end
  end

  skip "Latches: INPT4-INPT5 bit (6) and INPT6-INPT7 bit(7)"
end
