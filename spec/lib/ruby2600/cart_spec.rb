require 'spec_helper'

describe Ruby2600::Cart do
  let(:cart_4K) { Ruby2600::Cart.new(path_for_ROM :hello)   }
  let(:cart_2K) { Ruby2600::Cart.new(path_for_ROM :hello2k) }

  it 'silentlys ignore writes' do
    old_value = cart_4K[0x0000]

    cart_4K[0x0000] = rand(256)
    expect(cart_4K[0x0000]).to eq(old_value)
  end

  it 'loads a 2K ROM' do
    expect(cart_2K[0x0000]).to eq(0xA9)       # _000: LDA #02 (first instruction)
    expect(cart_2K[0x0001]).to eq(0x02)

    expect(cart_2K[0x07FE]).to eq(0x00)       # _FFE: word $F800     (BRK vector)
    expect(cart_2K[0x07FF]).to eq(0XF8)
  end

  it 'loads a 4K ROM' do
    expect(cart_4K[0x0000]).to eq(0xA9)       # _000: LDA #02 (first instruction)
    expect(cart_4K[0x0001]).to eq(0x02)

    expect(cart_4K[0x0FFE]).to eq(0x00)       # _FFE: word $F000     (BRK vector)
    expect(cart_4K[0x0FFF]).to eq(0XF0)
  end

  it 'maps a 2K ROM as a doubled 4k' do
    0x0000.upto(0x07FF) do |addr|
      expect(cart_2K[addr]).to eq(cart_2K[addr + 2048])
    end
  end
end
