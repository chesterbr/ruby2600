require 'spec_helper'

describe Ruby2600::TIACounter do

  subject(:counter) { Ruby2600::TIACounter.new }

  let(:sample_of_initial_values) { Array.new(100) { Ruby2600::TIACounter.new.value } }

  describe '#initialize' do
    it 'should initialize with a random value' do
      unique_value_count = sample_of_initial_values.uniq.length

      unique_value_count.should be > 1
    end

    it 'should initialize with valid values' do
      sample_of_initial_values.each do |value|
        value.should be_an Integer
        (0..39).should cover value
      end
    end

    context 'with event block' do
      before do
        counter.reset
        counter.on_change { |value| @last_value = value }
      end

      it 'should call the event block whenever (and only when) the counter changes' do
        4.times do
          @last_value.should be_nil
          counter.tick
        end

        counter.tick
        @last_value.should == 1

        counter.value = 38
        4.times { counter.tick }
        @last_value.should == 39

        4.times { counter.tick }
        @last_value.should == 0
      end
    end
  end

  describe '#reset' do
    before { counter.reset }
    its(:value) { should == 0 }
  end

  describe '#tick' do
    context 'ordinary values' do
      before { counter.value = rand(38) }

      it 'should increase once every 4 ticks' do
        original_value = counter.value

        2.times do
          3.times { counter.tick }
          expect { counter.tick }.to change { counter.value }.by 1
        end

        counter.value.should == original_value + 2
      end
    end

    context 'upper boundary (39)' do
      before { counter.value = 39 }

      it 'should reset to 0 after 4 ticks' do
        3.times { counter.tick }
        expect { counter.tick }.to change { counter.value }.to 0
      end
    end
  end

  describe '#move' do
    before { counter.value = 20 }

    it 'should not change tick count for a 0 move' do
      counter.move 0b0000
      3.times { counter.tick }
      expect { counter.tick }.to change { counter.value }.to 21
    end

    it 'should count as 1 tick for a +1 move' do
      counter.move 0b0001
      2.times { counter.tick }
      expect { counter.tick }.to change { counter.value }.to 21
    end

    it 'should count as 2 ticks for a +2 move' do
      counter.move 0b0010
      counter.tick
      expect { counter.tick }.to change { counter.value }.to 21
    end

    it 'should count as 3 ticks for a +3 move' do
      counter.move 0b0011
      expect { counter.tick }.to change { counter.value }.to 21
    end

    it 'should count as 4 ticks for +4' do
      expect { counter.move 0b0100 }.to change { counter.value}.to 21
    end

    it 'should count as 7 ticks for +7' do
      counter.move 0b0111
      expect { counter.tick }.to change { counter.value }.to 22
    end

    it 'should go back 1 tick for a -1 move' do
      counter.move 0b1111
      expect { counter.tick }.to change { counter.value }.to 20
    end

    it 'should go back 2 ticks for a -2 move' do
      counter.move 0b1110
      counter.tick
      expect { counter.tick }.to change { counter.value }.to 20
    end

    it 'should go back 3 ticks for a -2 move' do
      counter.move 0b1101
      2.times { counter.tick }
      expect { counter.tick }.to change { counter.value }.to 20
    end

    it "should go back 4 ticks for a -4 move" do
      counter.move 0b1100
      3.times { counter.tick }
      expect { counter.tick }.to change { counter.value }.to 20
    end

    it "should go back 8 ticks for a -8 move" do
      counter.move 0b1000
      7.times { counter.tick }
      expect { counter.tick }.to change { counter.value }.to 20
    end
  end
end
