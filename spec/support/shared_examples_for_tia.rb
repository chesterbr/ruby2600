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