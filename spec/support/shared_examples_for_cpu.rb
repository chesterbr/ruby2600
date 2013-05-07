shared_examples_for 'set a value' do |expected|
  it do
    cpu.step

    value = cpu.a
    value.should be(expected), "Expected: #{hex_byte(expected)}, found: #{hex_byte(value)}"
  end
end

shared_examples_for 'set x value' do |expected|
  it do
    cpu.step

    value = cpu.x
    value.should be(expected), "Expected: #{hex_byte(expected)}, found: #{hex_byte(value)}"
  end
end

shared_examples_for 'set y value' do |expected|
  it do
    cpu.step

    value = cpu.y
    value.should be(expected), "Expected: #{hex_byte(expected)}, found: #{hex_byte(value)}"
  end
end

shared_examples_for 'set memory with value' do |position, expected|
  it do
    cpu.step

    value = cpu.memory[position]
    value.should be(expected), "Expected: #{hex_byte(expected)} at address #{hex_word(position)}, found: #{hex_byte(value)}"
  end
end

shared_examples_for "set z flag" do
  it do
    cpu.step

    cpu.flags[:z].should be_true
  end
end

shared_examples_for "reset z flag" do
  it do
    cpu.step

    cpu.flags[:z].should be_false
  end
end

shared_examples_for "set n flag" do
  it do
    cpu.step

    cpu.flags[:n].should be_true
  end
end

shared_examples_for "reset n flag" do
  it do
    cpu.step

    cpu.flags[:n].should be_false
  end
end

shared_examples_for 'advance PC by one' do
  it { expect { cpu.step }.to change { cpu.pc }.by(1) }
end

shared_examples_for 'advance PC by two' do
  it { expect { cpu.step }.to change { cpu.pc }.by(2) }
end

shared_examples_for 'advance PC by three' do
  it { expect { cpu.step }.to change { cpu.pc }.by(3) }
end

shared_examples_for "take two cycles" do
  it { cpu.step.should == 2 }
end

shared_examples_for "take three cycles" do
  it { cpu.step.should == 3 }
end

shared_examples_for "take four cycles" do
  it { cpu.step.should == 4 }
end

shared_examples_for "take five cycles" do
  it { cpu.step.should == 5 }
end

shared_examples_for "take six cycles" do
  it { cpu.step.should == 6 }
end

