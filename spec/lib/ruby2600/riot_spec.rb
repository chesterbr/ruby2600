require 'spec_helper'

describe Ruby2600::Riot do
  it 'should store values on the RAM range' do
    (0x80..0xFF).each do |position|
      value = Random.rand(256)
      subject[position] = value
      subject[position].should be(value), "Failed for value $#{value.to_s(16)} at $#{position.to_s(16)}"
    end
  end
end
