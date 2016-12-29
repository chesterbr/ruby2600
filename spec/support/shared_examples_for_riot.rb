shared_examples_for 'a timer with clock interval' do |interval|
  let(:initial_value) { rand(50) + 200 }
  before { riot[timer_register] = initial_value }

  it 'decrements immediately after initialization' do
    expect(riot[INTIM]).to eq(initial_value - 1)
  end

  it 'reduces current value (INTM) on every 8th call' do
    10.times do
      (interval - 1).times { expect{ riot.tick }.to_not change{ riot[INTIM] } }
      expect{ riot.tick }.to change{ riot[INTIM] }.by -1
    end
  end

  it 'underflows gracefully' do
    riot[timer_register] = 0x02
    expect(riot[INTIM]).to eq(0x01)
    interval.times { riot.tick }
    expect(riot[INTIM]).to eq(0x00)
    interval.times { riot.tick }
    expect(riot[INTIM]).to eq(0xFF)
  end

  it 'underflows immediately after initialization with 0' do
    riot[timer_register] = 0
    expect(riot[INTIM]).to eq(0xFF)
  end

  it 'resets interval to 1 after underflow' do
    riot[timer_register] = 0x01
    interval.times { riot.tick }
    expect(riot[INTIM]).to eq(0xFF)
    riot.tick
    expect(riot[INTIM]).to eq(0xFE)
  end

  context 'instat (timer status)' do
    it 'has bits 6 & 7 clear if no underflow happened' do
      10.times do
        expect(riot[INSTAT][6]).to eq(0)
        expect(riot[INSTAT][7]).to eq(0)
        riot.tick
      end
    end

    it 'has bits 6 and 7 set after any underflow (and reset by an init)' do
      3.times do
        riot[timer_register] = 0x01
        expect(riot[INSTAT][6]).to eq(0)
        expect(riot[INSTAT][7]).to eq(0)
        interval.times { riot.tick }
        expect(riot[INSTAT][6]).to eq(1)
        expect(riot[INSTAT][7]).to eq(1)
        10.times do
          256.times { riot.tick } # interval now is 1
          expect(riot[INSTAT][6]).to eq(1)
          expect(riot[INSTAT][7]).to eq(1)
        end
      end
    end

    it 'has bit 6 clear after it is read' do
      riot[timer_register] = 0x01
      interval.times { riot.tick }
      expect(riot[INSTAT][6]).to eq(1)
      expect(riot[INSTAT][6]).to eq(0)
    end

    it 'does not have bit 7 affected by a read' do
      riot[timer_register] = 0x01
      interval.times { riot.tick }
      expect(riot[INSTAT][7]).to eq(1)
      expect(riot[INSTAT][7]).to eq(1)
    end

    it '"However, the interval is automatically re-actived when reading from the INTIM register, ie. the timer does then continue to decrement at interval speed (originated at the current value)."'
  end
end
