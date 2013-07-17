require 'spec_helper'

describe Ruby2600::TIAPlayer do

  let(:tia) { [] }
  subject(:player) { Ruby2600::TIAPlayer.new(tia) }

  def player_pixels(first, last)
    (first-1).times { player.pixel }
    (0..(last - first)).map { player.pixel }
  end

  describe 'pixel' do
    it 'should never output if GRP0 is all zeros' do
      tia[GRP0] = 0
      300.times { player.pixel.should be_nil }
    end

    context 'player drawing' do
      before do
        tia[GRP0] = 0b01010101             # A checkerboard pattern
        tia[NUSIZ0] = 0                    # no repetition
        tia[COLUP0] = 0xEE                 # whatever color
        rand(160).times { player.pixel }   # at an arbitrary screen position
        player.strobe
      end

      it 'after a strobe, it should output the player after a full scanline (160pixels) + 1-bit delay' do
        # Player is drawn on next scanline (160 pixels), delayed by 1 pixel
        161.times { player.pixel }
        player_pixels(1, 8).should == [nil, 0xEE, nil, 0xEE, nil, 0xEE, nil, 0xEE]
      end

      it 'should draw player again on second-after-current scanline' do
        321.times { player.pixel }
        player_pixels(1, 8).should == [nil, 0xEE, nil, 0xEE, nil, 0xEE, nil, 0xEE]
      end

      it 'should draw player on third-after-current scanline' do
        481.times { player.pixel }
        player_pixels(1, 8).should == [nil, 0xEE, nil, 0xEE, nil, 0xEE, nil, 0xEE]
      end

      context 'two copies' do
        before do
          tia[NUSIZ0] = 1
          player.strobe
        end

        it 'should draw the second copy of the player immediately' do          
          player_pixels(17, 24).should == [nil, 0xEE, nil, 0xEE, nil, 0xEE, nil, 0xEE]
        end
      end
    end

  end
end
