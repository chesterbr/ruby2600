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

    context '8 clock timer' do
      let(:initial_value) { rand(50) + 200 }
      before { riot[TIM8T] = initial_value }

      it 'should decrement immediately after initialization' do
        riot[INTIM].should == initial_value - 1
      end

      it 'should reduce current value (INTM) on every 8th call' do
        10.times do
          7.times { expect{ riot.pulse }.to_not change{ riot[INTIM] } }
          expect{ riot.pulse }.to change{ riot[INTIM] }.by -1
        end
      end

      it 'should underflow gracefully' do
        riot[TIM8T] = 0x02
        riot[INTIM].should == 0x01
        8.times { riot.pulse }
        riot[INTIM].should == 0x00
        8.times { riot.pulse }
        riot[INTIM].should == 0xFF
      end

      it 'should underflow immediately after initialization with 0' do
        riot[TIM8T] = 0
        riot[INTIM].should == 0xFF
        # FIXME check flags also
      end

      it 'should reset interval to 1 after underflow' do
        riot[TIM8T] = 0x01
        8.times { riot.pulse }
        riot[INTIM].should == 0xFF
        riot.pulse
        riot[INTIM].should == 0xFE
      end

      context 'instat (timer status)' do
        it 'should have bits 6 & 7 clear if no underflow happened' do
          10.times do
            riot[INSTAT][6].should == 0
            riot[INSTAT][7].should == 0
            riot.pulse
          end
        end

        it 'should have bits 6 and 7 set after any underflow (and reset by an init)' do
          3.times do
            riot[TIM8T] = 0x01
            riot[INSTAT][6].should == 0
            riot[INSTAT][7].should == 0
            8.times { riot.pulse }
            riot[INSTAT][6].should == 1
            riot[INSTAT][7].should == 1
            10.times do
              256.times { riot.pulse } # interval now is 1
              riot[INSTAT][6].should == 1
              riot[INSTAT][7].should == 1
            end
          end
        end

        it 'should have bit 6 clear after it is read' do
          riot[TIM8T] = 0x01
          8.times { riot.pulse }
          riot[INSTAT][6].should == 1
          riot[INSTAT][6].should == 0
        end

        it 'should not have bit 7 affected by a read' do
          riot[TIM8T] = 0x01
          8.times { riot.pulse }
          riot[INSTAT][7].should == 1
          riot[INSTAT][7].should == 1
        end
      end
    end
  end
end
