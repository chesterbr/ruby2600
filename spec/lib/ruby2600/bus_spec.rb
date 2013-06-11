require 'spec_helper'

describe Ruby2600::Bus do

  let(:cpu)  { double('cpu', :memory= => nil, :reset => nil) }
  let(:tia)  { double('tia', :cpu= => nil, :riot= => nil) }
  let(:cart) { double('cart') }
  let(:riot) { double('riot') }

  subject(:bus) { Ruby2600::Bus.new(cpu, tia, cart, riot) }

  # 6507 address lines (bits) A7 & A12 select which chip (TIA/RIOT/cart ROM)
  # will be read/written (and line A9 selects betwen RIOT's RAM and I/O+Timer).
  # See: http://nocash.emubase.de/2k6specs.htm#memorymirrors or
  #      http://atariage.com/forums/topic/192418-mirrored-memory

  ALL_ADDRESSES      = (0x0000..0xFFFF).to_a
  CART_ADDRESSES     = ALL_ADDRESSES.select { |a| a[12] == 1 }
  TIA_ADDRESSES      = ALL_ADDRESSES.select { |a| a[12] == 0 &&              a[7] == 0 }
  RIOT_IOT_ADDRESSES = ALL_ADDRESSES.select { |a| a[12] == 0 && a[9] == 1 && a[7] == 1 }
  RIOT_RAM_ADDRESSES = ALL_ADDRESSES.select { |a| a[12] == 0 && a[9] == 0 && a[7] == 1 }

  context 'initialization' do
    it 'should wire itself as a memory proxy for CPU' do
      cpu.should_receive(:memory=).with(bus)
    end

    it 'should wire TIA to CPU (so it can drive the CPU timing)' do
      tia.should_receive(:cpu=).with(cpu)

      bus
    end

    it 'should wire TIA to RIOT (so it can drive the timers)' do
      tia.should_receive(:riot=).with(riot)

      bus
    end

    it 'should reset CPU' do
      cpu.should_receive(:reset)

      bus
    end
  end

  context 'console switches' do
    before do
      riot.stub(:portB=)
      # FIXME add other "zero" states here
      bus.color_bw_switch = false
    end

    it 'should update RIOT with right value when color switch is set to COLOR' do
      riot.should_receive(:portB=).with(0b00001000)

      bus.color_bw_switch = true
    end

    it 'should update RIOT with right value when color switch is set to B/W' do
      riot.should_receive(:portB=).with(0b00000000)

      bus.color_bw_switch = false
    end
  end


  context 'CPU read/write' do

    # We need to check if reads/writes to the bus will read/write the
    # correct chip, but with a 64K-range, RSpec expectations will take
    # too long. Instead, we'll use arrays as chip stubs.

    let(:cart) { Array.new(4096) { rand(256) } }
    let(:tia)  { Array.new(32)   { rand(256) } }
    let(:riot) { Array.new(768)  { rand(256) } }

    before do
      tia.stub :cpu=
      tia.stub :riot=
    end

    describe '#read' do
      # FIXME there is a finer-grained mirroring for read, see http://nocash.emubase.de/2k6specs.htm#memorymirrors
      it 'translates TIA mirror reads to 00-3F' do
        TIA_ADDRESSES.each do |a|
          bus[a].should == tia[a &  0b0000000000111111]
        end
      end

      it 'translates RAM mirror reads to RIOT $00-$7F' do
        RIOT_RAM_ADDRESSES.each do |a|
          bus[a].should == riot[a & 0b0000000001111111]
        end
      end

      it 'translates I/O and timer mirror reads to RIOT $0280-$02FF' do
        RIOT_IOT_ADDRESSES.each do |a|
          bus[a].should == riot[a & 0b0000001011111111]
        end
      end

      it 'translates cart mirror reads to 0000-0FFF (4Kbytes)' do
        CART_ADDRESSES.each do |a|
          bus[a].should == cart[a & 0b0000111111111111]
        end
      end
    end

    describe '#write' do
      it 'translates TIA mirror writes to 00-3F' do
        TIA_ADDRESSES.each do |a|
          value = rand(256)
          bus[a] = value

          tia[a &  0b0000000000111111].should == value
        end
      end

      it 'translates RAM mirror writes to RIOT $00-$FF' do
        RIOT_RAM_ADDRESSES.each do |a|
          value = rand(256)
          bus[a] = value

          riot[a & 0b0000000001111111].should == value
        end
      end

      it 'translates I/O and timer mirror writes to RIOT $0280-$02FF' do
        RIOT_IOT_ADDRESSES.each do |a|
          value = rand(256)
          bus[a] = value

          riot[a & 0b0000001011111111].should == value
        end
      end

      it 'translates cart mirror writes (some are not ROM-only) to 0000-0FFF (4Kbytes)' do
        CART_ADDRESSES.each do |a|
          value = rand(256)
          bus[a] = value

          cart[a & 0b0000111111111111].should == value
        end
      end
    end
  end

  pending '2K carts / SARA / RIOT details from http://atariage.com/forums/topic/192418-mirrored-memory/'

end
