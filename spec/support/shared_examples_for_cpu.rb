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

shared_examples_for "take two cycles" do
  it do
    cpu.step.should == 2
  end
end

