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

  	it 'should set the flag' do
      tia.send(:update_collision_flags)

      tia[register][bit].should == 1
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

    it 'should set the flag' do
      tia.send(:update_collision_flags)

      tia[register][bit].should == 1
    end
  end

  def turn_on(object)
    tia.instance_variable_set("@#{object}_pixel", rand(256))
  end

  def turn_off(object)
    tia.instance_variable_set("@#{object}_pixel", nil)
  end
end

shared_examples_for 'reflect port input' do |port|
  it "should set/clear bit 7 on high/low level" do
    tia.set_port_level port, :low
    tia[INPT0 + port][7].should == 0

    tia.set_port_level port, :high
    tia[INPT0 + port][7].should == 1

    tia.set_port_level port, :low
    tia[INPT0 + port][7].should == 0
  end
end

shared_examples_for 'latch port input' do |port|
  [:high, :low].each do |previous_level|
    context "previous level was #{previous_level}" do
      it "INPT#{port} bit 7 should be 1 after enabling latch mode" do
        tia[VBLANK] = 0
        tia.set_port_level port, previous_level

        tia[VBLANK] = 0b01000000
        tia[INPT0 + port][7].should == 1
      end
    end
  end

  it "INPT#{port} bit 7 should latch to 0 once a low is received" do
    tia.set_port_level port, :high
    tia[INPT0 + port][7].should == 1

    tia.set_port_level port, :low
    tia[INPT0 + port][7].should == 0

    tia.set_port_level port, :high
    tia[INPT0 + port][7].should == 0

    tia.set_port_level port, :low
    tia[INPT0 + port][7].should == 0
  end

  it "should return to normal behavior after latching is disabled" do
    tia[VBLANK] = 0

    tia.set_port_level port, :low
    tia[INPT0 + port][7].should == 0

    tia.set_port_level port, :high
    tia[INPT0 + port][7].should == 1

    tia.set_port_level port, :low
    tia[INPT0 + port][7].should == 0
  end
end

shared_examples_for 'dump port to ground' do |port|
  it "INPT#{port} bit 7 should not be affected by input (should always be 0)" do
    tia.set_port_level port, :low
    tia[INPT0 + port][7].should == 0

    tia.set_port_level port, :high
    tia[INPT0 + port][7].should == 0

    tia.set_port_level port, :low
    tia[INPT0 + port][7].should == 0
  end
end