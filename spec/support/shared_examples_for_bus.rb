%w'tia riot cart'.each do |chip|
  shared_examples_for "read address range from #{chip}" do |range|
    it do
      range.each do |address|
        value = Random.rand(256)
        send(chip).stub(:[]).with(address).and_return(value)

        subject[address].should == value
      end
    end
  end

  shared_examples_for "write address range to #{chip}" do |range|
    it do
      range.each do |address|
        value = Random.rand(256)
        send(chip).should_receive(:[]=).with address, value

        subject[address] = value
      end
    end
  end
end

shared_examples_for 'set bits on RIOT after switch is set/pressed' do |bits, switch|
  it 'should update portB' do
    riot.should_receive(:portB=).with(bits)

    bus.send "#{switch}_switch=", true
  end
end

shared_examples_for 'set bits on RIOT after switch is reset/released' do |bits, switch|
  it 'should update portB' do
    riot.should_receive(:portB=).with(bits)

    bus.send "#{switch}_switch=", false
  end
end
