require 'spec_helper'

describe Ruby2600::Ball do

  let(:tia) { Array.new(64, 0) }
  subject(:ball) { Ruby2600::Ball.new(tia) }

  describe 'pixel' do
    let(:color) { [rand(255) + 1] }

    before do
      tia[COLUPF] = color[0]
      ball.strobe
    end

    it 'should never output if ENABL is disabled' do
      tia[ENABL] = 0
      
      pixels(ball, 1, 300).should == Array.new(300)
    end

    it 'should generate some output if ENABL is enabled' do
      tia[ENABL] = rand(256) | 0b10
      
      pixels(ball, 1, 300).should include(color[0])
    end

    context 'drawing (strobe)' do
      before do
        # Enable and strobe from an arbitrary position
        tia[ENABL] = rand(256) | 0b10
        rand(160).times { ball.pixel }
        ball.strobe
        4.times { ball.pixel } # 4-bit delay
      end

      context '1x' do
        before do
          tia[CTRLPF] = 0b00000000
        end

        it 'should draw immediately' do
          pixels(ball, 1, 160).should == color + Array.new(159)
        end

        it 'should NOT be affected by NUSZ0 (it is not player/missile)' do
          tia[NUSIZ0] = 1 

          pixels(ball, 1, 160).should == color + Array.new(159)
        end
      end
    end
  end
end
