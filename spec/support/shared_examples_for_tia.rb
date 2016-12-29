shared_examples_for 'update collision register bit for objects' do |register, bit, obj1, obj2|
  before do
    tia.reg[CXCLR] = 0
    %w'p0 p1 m0 m1 bl pf'.each { |obj| turn_off obj }
  end

  context 'both objects output' do
    before do
      turn_on obj1
      turn_on obj2
   end

  	it 'sets the flag' do
      tia.send(:update_collision_flags)

      expect(tia[register][bit]).to eq(1)
    end
  end

  context 'neither object outputs' do
    before do
      turn_off obj1
      turn_off obj2
    end

    it { expect { tia.send(:update_collision_flags) }.to_not change { tia[register][bit] } }
  end

  context 'only first object outputs' do
    before do
      turn_on obj1
      turn_off obj2
    end

  	it { expect { tia.send(:update_collision_flags) }.to_not change { tia[register][bit] } }
  end

  context 'only second object outputs' do
    before do
      turn_off obj1
      turn_on obj2
    end

    it { expect { tia.send(:update_collision_flags) }.to_not change { tia[register][bit] } }
  end

  context 'all objects output' do
    before do
      %w'p0 p1 m0 m1 bl pf'.each { |obj| turn_on obj}
    end

    it 'sets the flag' do
      tia.send(:update_collision_flags)

      expect(tia[register][bit]).to eq(1)
    end
  end

  def turn_on(object)
    allow(tia.instance_variable_get("@#{object}")).to receive(:pixel).and_return(rand(256))
  end

  def turn_off(object)
    allow(tia.instance_variable_get("@#{object}")).to receive(:pixel).and_return(nil)
  end
end

shared_examples_for 'reflect port input' do |port|
  it "sets/clears bit 7 on high/low level" do
    tia.set_port_level port, :low
    expect(tia[INPT0 + port][7]).to eq(0)

    tia.set_port_level port, :high
    expect(tia[INPT0 + port][7]).to eq(1)

    tia.set_port_level port, :low
    expect(tia[INPT0 + port][7]).to eq(0)
  end
end

shared_examples_for 'latch port input' do |port|
  context "- with the level initially high" do
    it "INPT#{port} bit 7 should latch to 0 once a low is received" do
      tia[VBLANK] = 0
      tia.set_port_level port, :high
      tia[VBLANK] = 0b01000000

      expect(tia[INPT0 + port][7]).to eq(1)

      tia.set_port_level port, :high
      expect(tia[INPT0 + port][7]).to eq(1)

      tia.set_port_level port, :low
      expect(tia[INPT0 + port][7]).to eq(0)

      tia.set_port_level port, :high
      expect(tia[INPT0 + port][7]).to eq(0)

      tia.set_port_level port, :low
      expect(tia[INPT0 + port][7]).to eq(0)
    end

    it "- INPT#{port} bit 7 should return to normal behavior after latching is disabled" do
      tia[VBLANK] = 0b01000000
      tia.set_port_level port, :high
      tia[VBLANK] = 0

      expect(tia[INPT0 + port][7]).to eq(1)

      tia.set_port_level port, :low
      expect(tia[INPT0 + port][7]).to eq(0)

      tia.set_port_level port, :high
      expect(tia[INPT0 + port][7]).to eq(1)

      tia.set_port_level port, :low
      expect(tia[INPT0 + port][7]).to eq(0)
    end
  end

  # Both the Stella manual and http://nocash.emubase.de/2k6specs.htm#controllersjoysticks
  # are imprecise on the real behaviour. This one is what Stella does, and it
  # is the only that simultaneously work with Pitfall, Donkey Kong and River Raid
  context "- with the level initially low" do
    it "INPT#{port} bit 7 should stay low, allow one high, then keep low" do
      tia[VBLANK] = 0
      tia.set_port_level port, :low
      tia[VBLANK] = 0b01000000

      expect(tia[INPT0 + port][7]).to eq(0)

      tia.set_port_level port, :high
      expect(tia[INPT0 + port][7]).to eq(1)

      tia.set_port_level port, :low
      expect(tia[INPT0 + port][7]).to eq(0)

      tia.set_port_level port, :high
      expect(tia[INPT0 + port][7]).to eq(0)

      tia.set_port_level port, :low
      expect(tia[INPT0 + port][7]).to eq(0)
    end

    it "- INPT#{port} bit 7 should return to normal behavior after latching is disabled" do
      tia.set_port_level port, :low
      tia[VBLANK] = 0b01000000
      tia[VBLANK] = 0

      expect(tia[INPT0 + port][7]).to eq(0)

      tia.set_port_level port, :low
      expect(tia[INPT0 + port][7]).to eq(0)

      tia.set_port_level port, :high
      expect(tia[INPT0 + port][7]).to eq(1)

      tia.set_port_level port, :low
      expect(tia[INPT0 + port][7]).to eq(0)
    end
  end
end

shared_examples_for 'dump port to ground' do |port|
  it "INPT#{port} bit 7 should not be affected by input (should always be 0)" do
    tia.set_port_level port, :low
    expect(tia[INPT0 + port][7]).to eq(0)

    tia.set_port_level port, :high
    expect(tia[INPT0 + port][7]).to eq(0)

    tia.set_port_level port, :low
    expect(tia[INPT0 + port][7]).to eq(0)
  end
end
