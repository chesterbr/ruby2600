require 'spec_helper'

describe Ruby2600::RIOT do

  subject(:riot) { Ruby2600::RIOT.new }

  it 'should initialize on a working state' do
    expect { riot.pulse }.to_not raise_error
  end

  describe 'ram (#ram)' do
    it 'should have lower 128 bytes available for reading/writing' do
      0.upto(127).each do |position|
        value = Random.rand(256)
        riot[position] = value
        riot[position].should be(value), "Failed for value $#{value.to_s(16)} at $#{position.to_s(16)}"
      end
    end
  end

  describe 'timer (#pulse / INTIM / INSTAT / TIM1T / TIM8T / TIM64T /T1024T)' do
    context '1-clock timer' do
      let(:timer_register) { TIM1T }

      it_should_behave_like 'a timer with clock interval', 1
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

  describe 'I/O port A (#portA= / SWACNT / SWCHA)' do
    before do
      riot[SWACNT] = 0b10101010 # 1 = output register, 0 = input port
      riot[SWCHA]  = 0b11001100 # set internal register to 1_0_1_0_
      riot.portA   = 0b01010011 # read input ports as      _1_1_0_1
    end

    it 'should read output bits from register and input bits from hardware port' do
      riot[SWCHA].should == 0b11011001 # combined result:  11011001
    end
  end

  describe 'I/O port B (#portB= / SWBCNT / SWCHB)' do
    before do
      riot[SWBCNT] = 0b00100101 # 1 = output register, 0 = input port
      riot[SWCHB]  = 0b11001100 # set internal register to __0__1_0
      riot.portB   = 0b01010011 # read input ports as      01_10_1_
    end

    it 'should read output bits from register and input bits from hardware port' do
      riot[SWCHB].should == 0b01010110 # combined result:  01010110
    end
  end
end
