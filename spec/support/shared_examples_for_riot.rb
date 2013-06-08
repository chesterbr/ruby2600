shared_examples_for 'a timer with clock interval' do |interval|
  let(:initial_value) { rand(50) + 200 }
  before { riot[timer_register] = initial_value }

  it 'should decrement immediately after initialization' do
    riot[INTIM].should == initial_value - 1
  end

  it 'should reduce current value (INTM) on every 8th call' do
    10.times do
      (interval - 1).times { expect{ riot.pulse }.to_not change{ riot[INTIM] } }
      expect{ riot.pulse }.to change{ riot[INTIM] }.by -1
    end
  end

  it 'should underflow gracefully' do
    riot[timer_register] = 0x02
    riot[INTIM].should == 0x01
    interval.times { riot.pulse }
    riot[INTIM].should == 0x00
    interval.times { riot.pulse }
    riot[INTIM].should == 0xFF
  end

  it 'should underflow immediately after initialization with 0' do
    riot[timer_register] = 0
    riot[INTIM].should == 0xFF
  end

  it 'should reset interval to 1 after underflow' do
    riot[timer_register] = 0x01
    interval.times { riot.pulse }
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
        riot[timer_register] = 0x01
        riot[INSTAT][6].should == 0
        riot[INSTAT][7].should == 0
        interval.times { riot.pulse }
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
      riot[timer_register] = 0x01
      interval.times { riot.pulse }
      riot[INSTAT][6].should == 1
      riot[INSTAT][6].should == 0
    end

    it 'should not have bit 7 affected by a read' do
      riot[timer_register] = 0x01
      interval.times { riot.pulse }
      riot[INSTAT][7].should == 1
      riot[INSTAT][7].should == 1
    end

    it '"However, the interval is automatically re-actived when reading from the INTIM register, ie. the timer does then continue to decrement at interval speed (originated at the current value)."'
  end
end
