require 'spec_helper'

describe Ruby2600::Cart do
  let(:cart_4K) { Ruby2600::Cart.new(path_for_ROM :hello) }

  it 'should silently ignore writes' do
    old_value = cart_4K[0x0000]

    cart_4K[0x0000] = rand(256)
    cart_4K[0x0000].should == old_value
  end

  it 'should map a 4K ROM' do
    cart_4K[0x0000].should == 0xA9       # F000: LDA #02 (first instruction)
    cart_4K[0x0001].should == 0x02

    cart_4K[0x0FFE].should == 0x00       # FFFE: word $F000     (BRK vector)
    cart_4K[0x0FFF].should == 0XF0
  end
end
