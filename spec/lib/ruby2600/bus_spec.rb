require 'spec_helper'

describe Ruby2600::Bus do

  let(:cpu)  { double('cpu', :memory= => nil, :reset => nil) }
  let(:tia)  { double('tia', :cpu= => nil) }
  let(:cart) { double('cart') }
  let(:riot) { double('riot') }

  subject(:bus) { Ruby2600::Bus.new(cpu, tia, cart, riot) }

  # 6507 address lines (bits) A7 & A12 select which chip (TIA/RIOT/cart ROM)
  # will be read/written. See: http://atariage.com/forums/topic/192418-mirrored-memory

  ALL_ADDRESSES  = (0x0000..0xFFFF).to_a
  CART_ADDRESSES = ALL_ADDRESSES.select { |a| a[12] == 1 }
  RIOT_ADDRESSES = ALL_ADDRESSES.select { |a| a[12] == 0 && a[7] == 1 }
  TIA_ADDRESSES  = ALL_ADDRESSES.select { |a| a[12] == 0 && a[7] == 0 }

  context 'initialization' do
    it 'should wire itself as a memory proxy for CPU' do
      cpu.should_receive(:memory=).with(bus)
    end

    it 'should wire TIA to CPU (so it can drive the CPU timing)' do
      tia.should_receive(:cpu=).with(cpu)

      bus
    end

    it 'should reset CPU' do
      cpu.should_receive(:reset)

      bus
    end
  end


  context 'CPU read/write' do

    # We need to check if reads/writes to the bus will read/write the
    # correct chip, but with a 64K-range, RSpec expectations will take
    # too long. Instead, we'll use arrays as chip stubs.

    let(:cart) { Array.new(4096) { rand(256) } }
    let(:tia)  { Array.new(64)   { rand(256) } }
    let(:riot) { Array.new(128)  { rand(256) } }

    before { tia.stub(:cpu=) }

    describe '#read' do
      it 'reads from TIA' do
        TIA_ADDRESSES.each do |a|
          bus[a].should == tia[a &  0b0000000000111111]
        end
      end

      it 'reads from RIOT' do
        RIOT_ADDRESSES.each do |a|
          bus[a].should == riot[a & 0b0000000001111111]
        end
      end

      it 'reads from CART (ROM)' do
        CART_ADDRESSES.each do |a|
          bus[a].should == cart[a & 0b0001111111111111]
        end
      end
    end

    describe '#write' do
      it 'writes to TIA' do
        TIA_ADDRESSES.each do |a|
          value = rand(256)
          bus[a] = value

          tia[a &  0b0000000000111111].should == value
        end
      end

      it 'writes to RIOT' do
        RIOT_ADDRESSES.each do |a|
          value = rand(256)
          bus[a] = value

          riot[a & 0b0000000001111111].should == value
        end
      end

      it 'does NOT write to cart (ROM == Read-Only-Memory)' do
        CART_ADDRESSES.each do |a|
          bus[a] = rand(256) # no mock should receive any message
        end
      end
    end
  end

  pending '2K carts / SARA / RIOT details from http://atariage.com/forums/topic/192418-mirrored-memory/'

end
