require 'spec_helper'

describe Ruby2600::Bus do

  let(:cpu)  { double('cpu', :memory= => nil, :reset => nil) }
  let(:tia)  { double('tia', :cpu= => nil) }
  let(:cart) { double('cart') }
  let(:riot) { double('riot') }

  subject(:bus) { Ruby2600::Bus.new(cpu, tia, cart, riot) }

  context 'initialization' do
    it 'should wire itself as a memory proxy for CPU' do
      cpu.should_receive(:memory=).with(bus)
    end

    it 'should wire TIA to CPU' do
      tia.should_receive(:cpu=).with(cpu)

      bus
    end

    it 'should reset CPU' do
      cpu.should_receive(:reset)

      bus
    end
  end

  describe '#read' do
    it_should 'read address range from tia',  0x0000..0x000D
    it_should 'read address range from riot', 0x0080..0x00FF

    it "should translate reads on address range $F000-FFFF to lower 4K range on cart" do
      0.upto(4095).each do |address|
        value = Random.rand(256)
        cart.stub(:[]).with(address).and_return(value)

        bus[0xF000 + address].should == value
      end
    end

  end

  describe '#write' do
    it_should 'write address range to tia',  0x0000..0x002C
    it_should 'write address range to riot', 0x0080..0x00FF
  end

  # TODO mirroring (TIA, at least, is mirrored in several pages)

end
