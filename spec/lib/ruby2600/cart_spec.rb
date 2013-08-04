require 'spec_helper'

describe Ruby2600::Cart do
  let(:cart_4K) { Ruby2600::Cart.new(path_for_ROM :hello)   }
  let(:cart_2K) { Ruby2600::Cart.new(path_for_ROM :hello2k) }

  it 'should silently ignore writes' do
    old_value = cart_4K[0x0000]

    cart_4K[0x0000] = rand(256)
    cart_4K[0x0000].should == old_value
  end

  it 'should load a 2K ROM' do
    cart_2K[0x0000].should == 0xA9       # _000: LDA #02 (first instruction)
    cart_2K[0x0001].should == 0x02

    cart_2K[0x07FE].should == 0x00       # _FFE: word $F800     (BRK vector)
    cart_2K[0x07FF].should == 0XF8
  end

  it 'should load a 4K ROM' do
    cart_4K[0x0000].should == 0xA9       # _000: LDA #02 (first instruction)
    cart_4K[0x0001].should == 0x02

    cart_4K[0x0FFE].should == 0x00       # _FFE: word $F000     (BRK vector)
    cart_4K[0x0FFF].should == 0XF0
  end

  it 'should map a 2K ROM as a doubled 4k' do
    0x0000.upto(0x07FF) do |addr|
      cart_2K[addr].should == cart_2K[addr + 2048]
    end
  end
end
