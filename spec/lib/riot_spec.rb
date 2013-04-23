require 'spec_helper'

describe Riot do
  it 'should store values on the RAM range' do
    (0x80..0xFF).each do |position|
      value = Random.rand(256)
      subject.write(position , value)
      subject.read(position).should == value
    end
  end
end
