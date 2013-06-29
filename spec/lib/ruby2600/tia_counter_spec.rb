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
  end

  describe '#reset' do
    before { counter.reset }
    its(:value) { should == 0 }
  end

  describe '#tick' do
    it 'should increase the value every 4 executions' do
      counter.value = rand(38)

      2.times do
        3.times { expect{counter.tick}.to_not change{counter.value} }
        expect{counter.tick}.to change{counter.value}.by 1
      end
    end

    it 'should reset the value to 0 if 39 and we tick 4 times' do
      counter.value = 39

      3.times { expect{counter.tick}.to_not change{counter.value} }
      expect{counter.tick}.to change{counter.value}.to 0
    end
  end



end
