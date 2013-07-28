require 'spec_helper'
include Ruby2600::Constants

describe Ruby2600::TIA do

  subject(:tia) do
    tia = Ruby2600::TIA.new
    tia.cpu = mock('cpu', :tick => nil, :halted= => nil)
    tia.riot = mock('riot', :tick => nil)
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


    it 'should get its color ahead of players/missiles if bit 2 is set (priority'

    # context 'RESBL/ENABL' do
    #   before { tia[COLUPF] = 0xC0 }

    #   def write_register_after_cycles(register, cpu_cycles)
    #     if @delay_counter.to_i <= cpu_cycles
    #       @delay_counter = @delay_counter.to_i + 1
    #       tia[register] = rand(256) if @delay_counter > cpu_cycles
    #     end
    #     1
    #   end

    #   context 'ENABL bit 1 reset' do
    #     before { tia[ENABL]  = 0 }

    #     it 'should not draw the ball on any scanline' do
    #       2.times { tia.scanline.should == Array.new(160, 0x00) }
    #     end
    #   end

    #   context 'ENABL bit 1 set' do
    #     before { tia[ENABL]  = 0b00000010 }

    #     context 'set during horizontal blank' do
    #       it 'should position ball on the left of screen, plus two pixels' do
    #         tia[RESBL] = rand(256)

    #         tia.scanline[0..2].should == [0x00, 0x00, 0xC0]
    #       end
    #     end

    #     context 'set on an arbitrary position' do
    #       before do
    #         tia.cpu.stub(:step) do
    #           write_register_after_cycles RESBL, 28
    #         end
    #         tia.scanline
    #       end

    #       it 'should position ball on the appropriate position of the following scanline' do
    #         expected = Array.new(160, 0x00)
    #         expected[15] = 0xC0

    #         tia.scanline.should == expected
    #       end
    #     end
    #   end
    # end
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
