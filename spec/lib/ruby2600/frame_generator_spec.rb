require 'spec_helper'

describe Ruby2600::FrameGenerator do
  let(:cpu)  { double('cpu', :tick => nil, :halted= => nil) }
  let(:tia)  { double('tia').as_null_object }
  let(:riot) { double('riot', :tick => nil) }

  subject(:frame_generator) { Ruby2600::FrameGenerator.new(cpu, tia, riot) }

  describe '#scanline' do
    context 'CPU timing' do
      it 'should spend 76 CPU cycles generating a scanline' do
        cpu.should_receive(:tick).exactly(76).times

        frame_generator.scanline
      end
    end

    context 'RIOT timing' do
      it 'should tick RIOT 76 times while generating a scanline, regardless of CPU timing' do
        riot.should_receive(:tick).exactly(76).times

        frame_generator.scanline
      end

      it 'should tick RIOT even if CPU is halted' do
        cpu.stub(:tick) { cpu.stub(:halted).and_return(:true) }
        riot.should_receive(:tick).exactly(76).times

        frame_generator.scanline
      end
    end

    it 'should "un-halt" the CPU before starting a new scanline (i.e., before its horizontal blank)' do
      cpu.should_receive(:halted=).with(false) do
        frame_generator.should_receive(:wait_horizontal_blank)
      end

      frame_generator.scanline
    end
  end

  it 'late hblank shifts everything'
end
