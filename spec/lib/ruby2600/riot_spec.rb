require 'spec_helper'

describe Ruby2600::RIOT do

  subject(:riot) { Ruby2600::RIOT.new }

  describe '#ram' do
    it 'should have lower 128 bytes available for reading/writing' do
      0.upto(127).each do |position|
        value = Random.rand(256)
        riot[position] = value
        riot[position].should be(value), "Failed for value $#{value.to_s(16)} at $#{position.to_s(16)}"
      end
    end
  end

  describe '#pulse' do
    context '1 clock interval' do
      before { riot[TIM1T] = rand(255) + 1 }
      it 'should reduce current value (INTIM) by one' do
        expect{ riot.pulse }.to change{ riot[INTIM] }.by -1
      end
    end

    context '8-clock timer' do
      let(:timer_register) { TIM8T }

      it_should_behave_like 'a timer with clock interval', 8
    end

    context '64-clock timer' do
      let(:timer_register) { TIM64T }

      it_should_behave_like 'a timer with clock interval', 64
    end

    context '1024-clock timer' do
      let(:timer_register) { T1024T }

      it_should_behave_like 'a timer with clock interval', 1024
    end
  end
end
