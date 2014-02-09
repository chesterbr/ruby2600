%w'tia riot cart'.each do |chip|
  shared_examples_for "read address range from #{chip}" do |range|
    it do
      range.each do |address|
        value = Random.rand(256)
        allow(send(chip)).to receive(:[]).with(address).and_return(value)

        expect(subject[address]).to eq(value)
      end
    end
  end

  shared_examples_for "write address range to #{chip}" do |range|
    it do
      range.each do |address|
        value = Random.rand(256)
        expect(send(chip)).to receive(:[]=).with address, value

        subject[address] = value
      end
    end
  end
end

shared_examples_for 'set bits on RIOT port after switch is set/pressed' do |port, bits, switch|
  it 'should update portB' do
    expect(riot).to receive("#{port}=").with(bits)

    bus.send "#{switch}=", true
  end
end

shared_examples_for 'set bits on RIOT port after switch is reset/released' do |port, bits, switch|
  it 'should update portB' do
    expect(riot).to receive("#{port}=").with(bits)

    bus.send "#{switch}=", false
  end
end
