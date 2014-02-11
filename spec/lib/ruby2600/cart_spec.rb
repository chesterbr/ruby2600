require 'spec_helper'
require 'fixtures/cart_arrays'

describe Ruby2600::Cart do
  let(:cart_4K) { Ruby2600::Cart.new(path_for_ROM :hello)   }
  let(:cart_2K) { Ruby2600::Cart.new(path_for_ROM :hello2k) }

  describe '#initialize' do
    it 'opens a file if given a filename (string)' do
      expect(File).to receive(:open).with('foo.bin', anything).
                      and_yield double('file').as_null_object

      Ruby2600::Cart.new('foo.bin')
    end

    it 'reads an array if one is given' do
      cart = Ruby2600::Cart.new([00, 11, 22, 33, 44, 55])

      expect(cart[5]).to eq(55)
    end

    # Opal can't run this spec (after all, we only support arrays because of it)
    if File.respond_to? :open
      def bytes(cart)
        result = Array.new(4096)
        0.upto(4095) do |i|
          result[i] = cart[i]
        end
        result
      end

      context '4K cart' do
        let(:cart_from_file)  { Ruby2600::Cart.new(path_for_ROM 'hello') }
        let(:cart_from_array) { Ruby2600::Cart.new(HELLO_CART_ARRAY) }

        it 'works the same with either array or filename' do
          expect(bytes(cart_from_file)).to eq(bytes(cart_from_array))
        end
      end
      context '2K cart' do
        let(:cart_from_file)  { Ruby2600::Cart.new(path_for_ROM 'hello2k') }
        let(:cart_from_array) { Ruby2600::Cart.new(HELLO2K_CART_ARRAY) }

        it 'works the same with either array or filename' do
          expect(bytes(cart_from_file)).to eq(bytes(cart_from_array))
        end
      end
    end
  end

  it 'should silently ignore writes' do
    old_value = cart_4K[0x0000]

    cart_4K[0x0000] = rand(256)
    expect(cart_4K[0x0000]).to eq(old_value)
  end

  it 'should load a 2K ROM' do
    expect(cart_2K[0x0000]).to eq(0xA9)       # _000: LDA #02 (first instruction)
    expect(cart_2K[0x0001]).to eq(0x02)

    expect(cart_2K[0x07FE]).to eq(0x00)       # _FFE: word $F800     (BRK vector)
    expect(cart_2K[0x07FF]).to eq(0XF8)
  end

  it 'should load a 4K ROM' do
    expect(cart_4K[0x0000]).to eq(0xA9)       # _000: LDA #02 (first instruction)
    expect(cart_4K[0x0001]).to eq(0x02)

    expect(cart_4K[0x0FFE]).to eq(0x00)       # _FFE: word $F000     (BRK vector)
    expect(cart_4K[0x0FFF]).to eq(0XF0)
  end

  it 'should map a 2K ROM as a doubled 4k' do
    0x0000.upto(0x07FF) do |addr|
      expect(cart_2K[addr]).to eq(cart_2K[addr + 2048])
    end
  end
end
