require 'spec_helper'

describe Ruby2600::RIOT do
  it 'should make 128 bytes of RAM available for reading/writing' do
    0.upto(127).each do |position|
      value = Random.rand(256)
      subject.ram[position] = value
      subject.ram[position].should be(value), "Failed for value $#{value.to_s(16)} at $#{position.to_s(16)}"
    end
  end
end
