require 'spec_helper'

describe Ruby2600::TIA do

  subject(:tia) do
    tia = Ruby2600::TIA.new
    tia.cpu = mock('cpu', :tick => nil, :halted= => nil)
    tia.riot = mock('riot', :tick => nil)

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
    it 'should initialize with random values on registers' do
      registers1 = Ruby2600::TIA.new.instance_variable_get(:@reg)
      registers2 = tia.instance_variable_get(:@reg)

      registers1.should_not == registers2
    end

    it "should initialize with valid (byte-size) values on registers" do
      tia.instance_variable_get(:@reg).each do |register_value|
        (0..255).should cover register_value
      end
    end
  end

  describe '#scanline' do
    before { clear_tia_registers }

    context 'TIA-CPU integration' do
      it 'should spend 76 CPU cycles generating a scanline' do
        tia.cpu.should_receive(:tick).exactly(76).times

        tia.scanline
      end
    end

    context 'TIA-RIOT integtation' do
      it 'should tick RIOT 76 times while generating a scanline, regardless of CPU timing' do
        tia.riot.should_receive(:tick).exactly(76).times

        tia.scanline
      end

      it 'should tick RIOT even if CPU is frozen by a write to WSYNC' do
        tia.cpu.stub(:tick) { tia[WSYNC] = rand(256) }
        tia.riot.should_receive(:tick).exactly(76).times

        tia.scanline
      end
    end

    context 'PF0, PF1, PF2' do
      before do
        tia[COLUBK] = 0xBB
        tia[COLUPF] = 0xFF
      end

      context 'all-zeros playfield' do
        it 'should generate a fullscanline with background color' do
          tia.scanline.should == Array.new(160, 0xBB)
        end
      end

      context 'all-ones playfield' do
        before { tia[PF0] = tia[PF1] = tia[PF2] = 0xFF }

        it 'should generate a fullscanline with foreground color' do
          tia.scanline.should == Array.new(160, 0xFF)
        end
      end

      context 'pattern playfield' do
        before do
          tia[PF0] = 0b01000101
          tia[PF1] = 0b01001011
          tia[PF2] = 0b01001011
        end

        it 'should generate matching pattern' do
          tia.scanline.should == [0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB,
                                  0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB]
        end
      end
    end

    context 'WSYNC' do
      it 'should halt the CPU if WSYNC is written to' do
        tia.cpu.should_receive(:halted=).with(true)

        tia[WSYNC] = rand(256)
      end

      it 'should "un-halt" the CPU before starting a new scanline (i.e., before its horizontal blank)' do
        tia.cpu.should_receive(:halted=).with(false) do
          tia.should_receive(:wait_horizontal_blank)
        end

        tia.scanline
      end
    end

    context 'VBLANK' do
      before do
        tia[COLUBK] = 0xBB
        tia[COLUPF] = 0xFF
        tia[PF0]    = 0xF0
        tia[PF1]    = 0xFF
        tia[PF2]    = 0xFF
      end

      it 'should generate a black scanline when "blanking" bit is set' do
        tia[VBLANK] = rand_with_bit(1, :set)

        tia.scanline.should == Array.new(160, 0x00)
      end

      it 'should generate a normal scanline when "blanking" bit is clear' do
        tia[VBLANK] = rand_with_bit(1, :clear)

        tia.scanline.should == Array.new(160, 0xFF)
      end

      pending "Latches: INPT4-INPT5 bit (6) and INPT6-INPT7 bit(7)"
    end

    it 'late hblank shifts everything'
  end

  describe '#topmost_pixel' do
    context 'CTRLPF priority bit clear' do
      before { tia[CTRLPF] = rand(256) & 0b011 }

      it { tia.should be_using_priority [:p0, :m0, :p1, :m1, :bl, :pf, :bk] }
    end

    context 'CTRLPF priority bit set' do
      before { tia[CTRLPF] = rand(256) | 0b100 }

      it { tia.should be_using_priority [:pf, :bl, :p0, :m0, :p1, :m1, :bk] }
    end

    class Ruby2600::TIA
      def using_priority?(enabled, others = [])
        # Assuming color = priority for enabled pixels and nil for others...
        enabled.count.times { |i| instance_variable_set "@#{enabled[i]}_pixel", i }
        others.each { |p| instance_variable_set "@#{p}_pixel", nil }
        # ...the first one (color = 0) should be the topmost...
        return false unless topmost_pixel == 0
        # ...and we disable it to recursively check the others, until none left
        first = enabled.shift
        enabled.empty? ? true : using_priority?(enabled, others << first)
      end
    end
  end

  describe '#[]=' do
    [
      VSYNC, VBLANK, RSYNC, NUSIZ0, NUSIZ1, COLUP0, COLUP1, COLUPF,
      COLUBK, CTRLPF, REFP0, REFP1, PF0, PF1, PF2, AUDC0, AUDC1, AUDF0,
      AUDF1, AUDV0, AUDV1, GRP0, GRP1, ENAM0, ENAM1, ENABL, HMP0, HMP1,
      HMM0, HMM1, HMBL, VDELP0, VDELP1, VDELBL
    ].each do |r|
      it "should store the value for #{r}" do
        value = rand(256)
        tia[r] = value

        tia.reg[r].should == value
      end
    end

    [
      WSYNC, RESP0, RESP1, RESM0, RESM1, RESBL, HMOVE, HMCLR, CXCLR,
      CXM0P, CXM1P, CXP0FB, CXP1FB, CXM0FB, CXM1FB, CXBLPF, CXPPMM,
      INPT0, INPT1, INPT2, INPT3, INPT4, INPT5
    ].each do |r|
      it "should not store the value for #{r}" do
        value = rand(256)
        tia.reg.should_not_receive(:[]=).with(r, value)

        tia[r] = value
      end
    end


    it 'should not store the value'
  end

  context 'positioning' do
    0.upto 1 do |n|
      describe "RESMP#{n}" do
        let(:player)  { tia.instance_variable_get "@p#{n}" }
        let(:missile) { tia.instance_variable_get "@m#{n}" }
        it "should reset m#{n}'s counter to p#{n}'s when strobed" do
          missile.counter.should_receive(:reset_to).with(player.counter)

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

      it 'should reset flags when written' do
        tia[CXCLR] = 0

        tia[CXM0P][6].should == 0
        tia[CXM0P][7].should == 0
        tia[CXM1P][6].should == 0
        tia[CXM1P][7].should == 0
        tia[CXP0FB][6].should == 0
        tia[CXP0FB][7].should == 0
        tia[CXP1FB][6].should == 0
        tia[CXP1FB][7].should == 0
        tia[CXM0FB][6].should == 0
        tia[CXM0FB][7].should == 0
        tia[CXM1FB][6].should == 0
        tia[CXM1FB][7].should == 0
        # Bit 6 of CXBLPF is not used
        tia[CXBLPF][7].should == 0
        tia[CXPPMM][6].should == 0
        tia[CXPPMM][7].should == 0
      end
    end

    describe '#update_collision_flags' do
      it_should 'update collision register bit for objects', CXM0P,  6, :m0, :p0
      it_should 'update collision register bit for objects', CXM0P,  7, :m0, :p1
      it_should 'update collision register bit for objects', CXM1P,  6, :m1, :p1
      it_should 'update collision register bit for objects', CXM1P,  7, :m1, :p0
      it_should 'update collision register bit for objects', CXP0FB, 6, :p0, :bl
      it_should 'update collision register bit for objects', CXP0FB, 7, :p0, :pf
      it_should 'update collision register bit for objects', CXP1FB, 6, :p1, :bl
      it_should 'update collision register bit for objects', CXP1FB, 7, :p1, :pf
      it_should 'update collision register bit for objects', CXM0FB, 6, :m0, :bl
      it_should 'update collision register bit for objects', CXM0FB, 7, :m0, :pf
      it_should 'update collision register bit for objects', CXM1FB, 6, :m1, :bl
      it_should 'update collision register bit for objects', CXM1FB, 7, :m1, :pf
      # Bit 6 of CXBLPF is not used
      it_should 'update collision register bit for objects', CXBLPF, 7, :bl, :pf
      it_should 'update collision register bit for objects', CXPPMM, 6, :m0, :m1
      it_should 'update collision register bit for objects', CXPPMM, 7, :p0, :p1
    end
  end

  describe '#set_port_level / VBLANK register input control' do
    context 'normal mode' do
      before { tia[VBLANK] = 0 }

      0.upto(5) { |p| it_should 'reflect port input', p }
    end

    context 'latched mode' do
      before { tia[VBLANK] = 0b01000000 }

      0.upto(3) { |p| it_should 'reflect port input', p }
      4.upto(5) { |p| it_should 'latch port input', p}
    end

    context 'grounded mode' do
      before { tia[VBLANK] = 0b10000000 }

      0.upto(3) { |p| it_should 'dump port to ground', p }
      4.upto(5) { |p| it_should 'reflect port input', p }
    end

    context 'latched + grounded mode' do
      before { tia[VBLANK] = 0b11000000 }

      0.upto(3) { |p| it_should 'dump port to ground', p }
      4.upto(5) { |p| it_should 'latch port input', p}
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
      xit "should generate a frame with #{lines} scanlines" do
        tia.cpu.stub(:tick) { build_frame(lines) }

        tia[VSYNC] = rand_with_bit 1, :clear
        tia.frame
        tia.frame.size.should == lines
      end
    end
  end
end
