require 'spec_helper'

describe Ruby2600::Counter do

  let(:subject) { Ruby2600::Counter.new }
  let(:sample_of_initial_values) { Array.new(100) { Ruby2600::Counter.new.value } }

  describe '#initialize' do
    it 'should initialize with a random value' do
      unique_value_count = sample_of_initial_values.uniq.length

      expect(unique_value_count).to be > 1
    end

    it 'should initialize with valid values' do
      sample_of_initial_values.each do |value|
        expect(value).to be_an Integer
        expect(0..39).to cover value
      end
    end
  end

  describe 'on_change' do
    let(:callback_double) { double 'callback' }
    before { subject.on_change(callback_double) }

    it 'should be triggered every 4th call' do
      subject.value = rand(40)
      3.times { subject.tick }
      expect(callback_double).to receive(:on_counter_change)

      subject.tick
    end

    it 'should be triggered on wrap' do
      subject.value = 38
      expect(callback_double).to receive(:on_counter_change).twice

      8.times { subject.tick }
    end
  end

  describe '#strobe' do
    it 'should reset counter with RESET value from http://www.atarihq.com/danb/files/TIA_HW_Notes.txt' do
      subject.reset
      expect(subject.value).to eq(39)
    end
  end

  describe '#tick' do
    context 'ordinary values' do
      before { subject.value = rand(38) }

      it 'should increase value once every 4 ticks' do
        original_value = subject.value

        2.times do
          3.times { subject.tick }
          expect { subject.tick }.to change { subject.value }.by 1
        end

        expect(subject.value).to eq(original_value + 2)
      end
    end

    context 'upper boundary (39)' do
      before { subject.value = 39 }

      it 'should wrap to 0' do
        3.times { subject.tick }
        expect { subject.tick }.to change { subject.value }.to 0
      end
    end
  end

  describe '#start_hmove / #apply_hmove' do
    before { subject.value = 20 }

    # When HMOVE is strobed, TIA (and the TIA class here) extends the
    # horizontal blank (and shortens the visible scanline) by 8 pixels,
    # pushing every movable object 8 pixels to the right.
    # Then it compensates by inserting additional clocks, from none
    # (for a -8 move) to 15 (for a +7 move). THAT is done by #apply_move

    it 'should add no extra CLK ticks for a -8 move' do
      value = 0b10000000
      subject.start_hmove value

      expect(subject).not_to receive(:tick)

      16.times { subject.apply_hmove value }
    end

    it 'should add 1 extra CLK ticks for a -7 move' do
      value = 0b10010000
      subject.start_hmove value

      expect(subject).to receive(:tick).once

      16.times { subject.apply_hmove value }
    end

    it 'should add 2 extra CLK ticks for a -6 move' do
      value = 0b10100000
      subject.start_hmove value

      expect(subject).to receive(:tick).twice

      16.times { subject.apply_hmove value }
    end

    it 'should add 6 extra CLK ticks for a -2 move' do
      value = 0b11100000
      subject.start_hmove value

      expect(subject).to receive(:tick).exactly(6).times

      16.times { subject.apply_hmove value }
    end

    it 'should add 7 extra CLK ticks for a -1 move' do
      value = 0b11110000
      subject.start_hmove value

      expect(subject).to receive(:tick).exactly(7).times

      16.times { subject.apply_hmove value }
    end


    it 'should add 8 extra CLK ticks for a 0 move' do
      value = 0
      subject.start_hmove value

      expect(subject).to receive(:tick).exactly(8).times

      16.times { subject.apply_hmove value }
    end

    it 'should add 12 extra CLK ticks for a +4 move' do
      value = 0b01000000
      subject.start_hmove value

      expect(subject).to receive(:tick).exactly(12).times

      16.times { subject.apply_hmove value }
    end

    it 'should add 15 extra CLK ticks for a +7 move' do
      value = 0b01110000
      subject.start_hmove value

      expect(subject).to receive(:tick).exactly(15).times

      16.times { subject.apply_hmove value }
    end
  end
end
