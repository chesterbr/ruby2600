require 'spec_helper'

describe Ruby2600::Graphic do

  let(:subject) { Ruby2600::Graphic.new(tia) }
  let(:tia) { double 'tia', :reg => Array.new(64, 0) }

  describe '#reg' do
    context 'p0 / m0 / bl' do
      let(:subject) { Ruby2600::Graphic.new(tia, 0) }

      it 'should always read the requested register' do
        expect(tia.reg).to receive(:[]).with(HMP0)

        subject.send(:reg, HMP0)
      end
    end

    context 'p1 / m1' do
      let(:subject) { Ruby2600::Graphic.new(tia, 1) }

      it 'should read the matching register for the other object' do
        expect(tia.reg).to receive(:[]).with(HMP1)

        subject.send(:reg, HMP0)
      end
    end
  end

  describe '#pixel' do
    shared_examples_for 'reflect graphic bit' do
      it 'by being nil if the graphic bit is clear' do
        subject.instance_variable_set(:@graphic_bit_value, 0)

        expect(subject.pixel).to eq(nil)
      end

      it "by being the graphic color register's value if the graphic bit is set" do
        subject.instance_variable_set(:@graphic_bit_value, 1)

        expect(subject.pixel).to eq(0xAB)
      end
    end

    before do
      allow(subject).to receive :tick
      allow(subject).to receive :tick_graphic_circuit
      subject.class.color_register = [COLUPF, COLUP0, COLUP1].sample
      tia.reg[subject.class.color_register] = 0xAB
    end

    # REVIEW these
    # context 'in visible scanline' do
    #   it 'should tick the counter' do
    #     subject.counter.should_receive(:tick)

    #     subject.pixel
    #   end

    #   it 'should advance the graphic bit' do
    #     subject.should_receive(:tick_graphic_circuit)

    #     subject.pixel
    #   end

    #   it_should 'reflect graphic bit'
    # end

    # context 'in extended hblank (aka "comb effect", caused by HMOVE during hblank)' do
    #   it 'should not tick the counter' do
    #     subject.counter.should_not_receive(:tick)

    #     subject.pixel :extended_hblank => true
    #   end

    #   it 'should not advance the graphic' do
    #     subject.should_not_receive(:tick_graphic_circuit)

    #     subject.pixel :extended_hblank => true
    #   end

    #   it_should 'reflect graphic bit' # (won't be displayed, but needed for collision checking)
    # end
  end
end
