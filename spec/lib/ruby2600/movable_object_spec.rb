require 'spec_helper'

describe Ruby2600::MovableObject do

  let(:sample_of_initial_values) { Array.new(100) { Ruby2600::MovableObject.new.value } }

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
  end

  describe 'on_counter_change' do    
    it 'should be triggered every 4th call' do
      subject.value = rand(40)
      3.times { subject.tick }
      subject.should_receive(:on_counter_change)

      subject.tick
    end

    it 'should be triggered on wrap' do
      subject.value = 38
      subject.should_receive(:on_counter_change).twice

      8.times { subject.tick }
    end
  end

  describe '#reset' do
    it 'should use RESET value from http://www.atarihq.com/danb/files/TIA_HW_Notes.txt' do
      subject.reset
      subject.value.should == 39
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

        subject.value.should == original_value + 2
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

end
