require 'spec_helper'

describe Ruby2600::MovableObject do

  let(:subject) { Ruby2600::MovableObject.new(tia) }
  let(:tia) { mock 'tia', :reg => Array.new(64, 0) }

  describe '#reg' do
    context 'p0 / m0 / bl' do
      let(:subject) { Ruby2600::MovableObject.new(tia, 0) }

      it 'should always read the requested register' do
        tia.reg.should_receive(:[]).with(HMP0)

        subject.send(:reg, HMP0)
      end
    end

    context 'p1 / m1' do
      let(:subject) { Ruby2600::MovableObject.new(tia, 1) }

      it 'should read the matching register for the other object' do
        tia.reg.should_receive(:[]).with(HMP1)

        subject.send(:reg, HMP0)
      end
    end
  end

  describe '#pixel' do
    shared_examples_for 'reflect graphic bit' do
      it 'by being nil if the graphic bit is clear' do
        subject.instance_variable_set(:@pixel_bit, 0)

        subject.pixel.should == nil
      end

      it "by being the graphic color register's value if the graphic bit is set" do
        subject.instance_variable_set(:@pixel_bit, 1)

        subject.pixel.should == 0xAB
      end
    end

    before do
      subject.stub :tick
      subject.stub :update_pixel_bit
      subject.class.color_register = [COLUPF, COLUP0, COLUP1].sample
      tia.reg[subject.class.color_register] = 0xAB
    end

    context 'in visible scanline' do
      it 'should tick the counter' do
        subject.counter.should_receive(:tick)

        subject.pixel
      end

      it 'should advance the graphic bit' do
        subject.should_receive(:update_pixel_bit)

        subject.pixel
      end

      it_should 'reflect graphic bit'
    end

    context 'in extended hblank (aka "comb effect", caused by HMOVE during hblank)' do
      it 'should not tick the counter' do
        subject.counter.should_not_receive(:tick)

        subject.pixel :extended_hblank => true
      end

      it 'should not advance the graphic' do
        subject.should_not_receive(:update_pixel_bit)

        subject.pixel :extended_hblank => true
      end

      it_should 'reflect graphic bit' # (won't be displayed, but needed for collision checking)
    end
  end

  describe '#start_hmove / #apply_hmove' do
    before do
      Ruby2600::MovableObject.hmove_register = HMP0
      subject.counter.value = 20
    end

    # When HMOVE is strobed, TIA (and the TIA class here) extends the
    # horizontal blank (and shortens the visible scanline) by 8 pixels,
    # pushing every movable object 8 pixels to the right.
    # Then it compensates by inserting additional clocks, from none
    # (for a -8 move) to 15 (for a +7 move). THAT is done by #apply_move

    it 'should add no extra CLK ticks for a -8 move' do
      tia.reg[HMP0] = 0b10000000
      subject.start_hmove

      subject.should_not_receive(:tick)

      16.times { subject.apply_hmove }
    end

    it 'should add 1 extra CLK ticks for a -7 move' do
      tia.reg[HMP0] = 0b10010000
      subject.start_hmove

      subject.should_receive(:tick).once

      16.times { subject.apply_hmove }
    end

    it 'should add 2 extra CLK ticks for a -6 move' do
      tia.reg[HMP0] = 0b10100000
      subject.start_hmove

      subject.should_receive(:tick).twice

      16.times { subject.apply_hmove }
    end

    it 'should add 6 extra CLK ticks for a -2 move' do
      tia.reg[HMP0] = 0b11100000
      subject.start_hmove

      subject.should_receive(:tick).exactly(6).times

      16.times { subject.apply_hmove }
    end

    it 'should add 7 extra CLK ticks for a -1 move' do
      tia.reg[HMP0] = 0b11110000
      subject.start_hmove

      subject.should_receive(:tick).exactly(7).times

      16.times { subject.apply_hmove }
    end


    it 'should add 8 extra CLK ticks for a 0 move' do
      tia.reg[HMP0] = 0
      subject.start_hmove

      subject.should_receive(:tick).exactly(8).times

      16.times { subject.apply_hmove }
    end

    it 'should add 12 extra CLK ticks for a +4 move' do
      tia.reg[HMP0] = 0b01000000
      subject.start_hmove

      subject.should_receive(:tick).exactly(12).times

      16.times { subject.apply_hmove }
    end

    it 'should add 15 extra CLK ticks for a +7 move' do
      tia.reg[HMP0] = 0b01110000
      subject.start_hmove

      subject.should_receive(:tick).exactly(15).times

      16.times { subject.apply_hmove }
    end
  end
end
