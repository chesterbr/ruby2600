require 'spec_helper'

describe Ruby2600::Bus do

  let(:cpu)  { double('cpu', :memory= => nil, :reset => nil) }
  let(:tia)  { double('tia', :cpu= => nil, :riot= => nil, :reg => Array.new(64, rand(256))) }
  let(:cart) { double('cart') }
  let(:riot) { double('riot', :portA= => nil, :portB= => nil) }

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
      pending "this auto-conversion did not work, because now we make a reference to bus before the time"

      expect(cpu).to receive(:memory=).with(bus)
    end

    it 'should wire TIA to CPU (so it can drive the CPU timing)' do
      expect(tia).to receive(:cpu=).with(cpu)

      bus
    end

    it 'should wire TIA to RIOT (so it can drive the timers)' do
      expect(tia).to receive(:riot=).with(riot)

      bus
    end

    it 'should reset CPU' do
      expect(cpu).to receive(:reset)

      bus
    end

    it 'should put all switches and inputs in default (reset/released) position' do
      # FIXME button 0 (on TIA)
      expect(riot).to receive(:portA=).with(0b11111111)
      expect(riot).to receive(:portB=).with(0b11111111)

      bus
    end
  end

  describe 'p0_joystick' do
    before do
      bus.p0_joystick_up    = false
      bus.p0_joystick_down  = false
      bus.p0_joystick_left  = false
      bus.p0_joystick_right = false
    end

    context 'normal directions' do
      it_should 'set bits on RIOT port after switch is set/pressed',    :portA, 0b11101111, :p0_joystick_up
      it_should 'set bits on RIOT port after switch is set/pressed',    :portA, 0b11011111, :p0_joystick_down
      it_should 'set bits on RIOT port after switch is set/pressed',    :portA, 0b10111111, :p0_joystick_left
      it_should 'set bits on RIOT port after switch is set/pressed',    :portA, 0b01111111, :p0_joystick_right
      it_should 'set bits on RIOT port after switch is reset/released', :portA, 0b11111111, :p0_joystick_up
      it_should 'set bits on RIOT port after switch is reset/released', :portA, 0b11111111, :p0_joystick_down
      it_should 'set bits on RIOT port after switch is reset/released', :portA, 0b11111111, :p0_joystick_left
      it_should 'set bits on RIOT port after switch is reset/released', :portA, 0b11111111, :p0_joystick_right
    end

    context 'diagonal left + (up|down)' do
      before { bus.p0_joystick_left = true }

      it_should 'set bits on RIOT port after switch is set/pressed',    :portA, 0b10101111, :p0_joystick_up
      it_should 'set bits on RIOT port after switch is reset/released', :portA, 0b10111111, :p0_joystick_up
      it_should 'set bits on RIOT port after switch is set/pressed',    :portA, 0b10011111, :p0_joystick_down
      it_should 'set bits on RIOT port after switch is reset/released', :portA, 0b10111111, :p0_joystick_down
    end

    context 'diagonal right + (up|down)' do
      before { bus.p0_joystick_right = true }

      it_should 'set bits on RIOT port after switch is set/pressed',    :portA, 0b01101111, :p0_joystick_up
      it_should 'set bits on RIOT port after switch is reset/released', :portA, 0b01111111, :p0_joystick_up
      it_should 'set bits on RIOT port after switch is set/pressed',    :portA, 0b01011111, :p0_joystick_down
      it_should 'set bits on RIOT port after switch is reset/released', :portA, 0b01111111, :p0_joystick_down
    end

    context 'fire button' do
      it 'should put TIA input port 4 on low when pressed' do
        expect(tia).to receive(:set_port_level).with(4, :low)

        bus.p0_joystick_fire = true
      end

      it 'should put TIA input port 4 on high when released' do
        expect(tia).to receive(:set_port_level).with(4, :high)

        bus.p0_joystick_fire = false
      end
    end
  end

  context 'console switches' do
    before do
      bus.color_bw_switch      = false
      bus.reset_switch         = false
      bus.select_switch        = false
      bus.p0_difficulty_switch = false
      bus.p1_difficulty_switch = false
    end

    context 'single-switch press/release' do
      it_should 'set bits on RIOT port after switch is set/pressed',    :portB, 0b11111110, :reset_switch
      it_should 'set bits on RIOT port after switch is set/pressed',    :portB, 0b11111101, :select_switch
      it_should 'set bits on RIOT port after switch is set/pressed',    :portB, 0b11110111, :color_bw_switch
      it_should 'set bits on RIOT port after switch is set/pressed',    :portB, 0b10111111, :p0_difficulty_switch
      it_should 'set bits on RIOT port after switch is set/pressed',    :portB, 0b01111111, :p1_difficulty_switch
      it_should 'set bits on RIOT port after switch is reset/released', :portB, 0b11111111, :reset_switch
      it_should 'set bits on RIOT port after switch is reset/released', :portB, 0b11111111, :select_switch
      it_should 'set bits on RIOT port after switch is reset/released', :portB, 0b11111111, :color_bw_switch
      it_should 'set bits on RIOT port after switch is reset/released', :portB, 0b11111111, :p0_difficulty_switch
      it_should 'set bits on RIOT port after switch is reset/released', :portB, 0b11111111, :p1_difficulty_switch
    end

    context 'multiple switches' do
      context 'P1 difficulty set (A)' do
        before { bus.p1_difficulty_switch = true }

        it_should 'set bits on RIOT port after switch is set/pressed',    :portB, 0b01111101, :select_switch
        it_should 'set bits on RIOT port after switch is reset/released', :portB, 0b01111111, :select_switch
      end

      context 'everything but reset set/pressed' do
        before do
          bus.select_switch = true
          bus.color_bw_switch = true
          bus.p0_difficulty_switch = true
          bus.p1_difficulty_switch = true
        end

        it_should 'set bits on RIOT port after switch is set/pressed', :portB, 0b00110100, :reset_switch
        it_should 'set bits on RIOT port after switch is reset/released', :portB, 0b00110101, :reset_switch
      end
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
      allow(tia).to receive :cpu=
      allow(tia).to receive :riot=
      allow(riot).to receive :portA=
      allow(riot).to receive :portB=
    end

    describe '#read' do
      it 'translates TIA mirror reads to 30-3F' do
        TIA_ADDRESSES.each do |a|
          expect(bus[a]).to eq(tia[a & 0b1111 | 0b110000])
        end
      end

      it 'translates RAM mirror reads to RIOT $00-$7F' do
        RIOT_RAM_ADDRESSES.each do |a|
          expect(bus[a]).to eq(riot[a & 0b0000000001111111])
        end
      end

      it 'translates I/O and timer mirror reads to RIOT $0280-$02FF' do
        RIOT_IOT_ADDRESSES.each do |a|
          expect(bus[a]).to eq(riot[a & 0b0000001011111111])
        end
      end

      it 'translates cart mirror reads to 0000-0FFF (4Kbytes)' do
        CART_ADDRESSES.each do |a|
          expect(bus[a]).to eq(cart[a & 0b0000111111111111])
        end
      end
    end

    describe '#write' do
      it 'translates TIA mirror writes to 00-3F' do
        TIA_ADDRESSES.each do |a|
          value = rand(256)
          bus[a] = value

          expect(tia[a &  0b0000000000111111]).to eq(value)
        end
      end

      it 'translates RAM mirror writes to RIOT $00-$FF' do
        RIOT_RAM_ADDRESSES.each do |a|
          value = rand(256)
          bus[a] = value

          expect(riot[a & 0b0000000001111111]).to eq(value)
        end
      end

      it 'translates I/O and timer mirror writes to RIOT $0280-$02FF' do
        RIOT_IOT_ADDRESSES.each do |a|
          value = rand(256)
          bus[a] = value

          expect(riot[a & 0b0000001011111111]).to eq(value)
        end
      end

      it 'translates cart mirror writes (some are not ROM-only) to 0000-0FFF (4Kbytes)' do
        CART_ADDRESSES.each do |a|
          value = rand(256)
          bus[a] = value

          expect(cart[a & 0b0000111111111111]).to eq(value)
        end
      end
    end
  end

  pending '2K carts / SARA / RIOT details from http://atariage.com/forums/topic/192418-mirrored-memory/'

end
