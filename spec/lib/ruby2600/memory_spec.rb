require 'spec_helper'

describe Ruby2600::Memory do
  let(:riot) { double('riot') }
  let(:cart) { double('cart') }
  let(:tia)  { double('tia')  }
  subject { Ruby2600::Memory.new(riot, cart, tia) }

  describe '#read' do
    it_has_behavior 'reads_from_correct_chip', (0x0000..0x000D), :tia
    it_has_behavior 'reads_from_correct_chip', (0x0080..0x00FF), :riot
    it_has_behavior 'reads_from_correct_chip', (0xFF00..0xFFFF), :cart
  end

  describe '#write' do
    it_has_behavior 'writes_to_correct_chip', (0x0000..0x002C), :tia
    it_has_behavior 'writes_to_correct_chip', (0x0080..0x00FF), :riot
  end


end
