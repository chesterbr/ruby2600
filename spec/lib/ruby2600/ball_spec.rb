require 'spec_helper'

describe Ruby2600::Ball do

  let(:tia) { double 'tia', :reg => Array.new(64, 0), :scanline_stage => :visible }
  subject(:ball) { Ruby2600::Ball.new(tia) }

  describe 'pixel' do
    let(:color) { [rand(255) + 1] }

    before do
      tia.reg[COLUPF] = color[0]
      ball.reset
    end

    it 'nevers output if ENABL is disabled' do
      tia.reg[ENABL] = 0

      pixels(ball, 1, 300).  == Array.new(300)
    end

    it 'generates some output if ENABL is enabled' do
      tia.reg[ENABL] = rand(256) | 0b10

      expect(pixels(ball, 1, 300)).to include(color[0])
    end

    context 'drawing (strobe)' do
      before do
        # Enable and strobe from an arbitrary position
        tia.reg[ENABL] = rand(256) | 0b10
        rand(160).times { ball.tick }
        ball.reset
        4.times { ball.tick } # 4-bit delay
      end

      context '1x' do
        before { tia.reg[CTRLPF] = 0b00000000 }

        it 'draws 1x ball on current scanline' do
          expect(pixels(ball, 1, 160)).to eq(scanline_with_object(1, color[0]))
        end

        it 'NOTs be affected by NUSZ0 (it is not player/missile)' do
          tia.reg[NUSIZ0] = 1

          expect(pixels(ball, 1, 160)).to eq(scanline_with_object(1, color[0]))
        end
      end

      context '2x' do
        before { tia.reg[CTRLPF] = 0b00010000 }

        it { expect(pixels(ball, 1, 160)).to eq(scanline_with_object(2, color[0])) }
      end

      context '4x' do
        before { tia.reg[CTRLPF] = 0b00100000 }

        it { expect(pixels(ball, 1, 160)).to eq(scanline_with_object(4, color[0])) }
      end

      context '8x' do
        before { tia.reg[CTRLPF] = 0b00110000 }

        it { expect(pixels(ball, 1, 160)).to eq(scanline_with_object(8, color[0])) }
      end
    end
  end
end
