require 'spec_helper'

describe Ruby2600::TIAPlayer do

  let(:tia) { Array.new(32, 0) }
  subject(:player) { Ruby2600::TIAPlayer.new(tia, 0) }

  def pixels(player, first, last)
    (first-1).times { player.pixel }
    (0..(last - first)).map { player.pixel }
  end

  context 'player 1' do
    subject(:player1) { Ruby2600::TIAPlayer.new(tia, 1) }

    before do 
      tia[GRP0] = 0x00
      tia[COLUP0] = 0x00
      tia[COLUP1] = 0xFF
      player1.strobe
      160.times { player1.pixel }
    end

    it 'should not draw anything without GRP1' do      
      pixels(player1, 1, 160).should_not include(0xFF)
    end

    it 'should draw if GRP1 is set' do
      tia[GRP1] = 0xFF
      pixels(player1, 1, 160).should include(0xFF)
    end
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
        pixels(player, 1, 8).should == [nil, 0xEE, nil, 0xEE, nil, 0xEE, nil, 0xEE]
      end

      it 'should draw player again on second-after-current scanline' do
        321.times { player.pixel }
        pixels(player, 1, 8).should == [nil, 0xEE, nil, 0xEE, nil, 0xEE, nil, 0xEE]
      end

      it 'should draw player on third-after-current scanline' do
        481.times { player.pixel }
        pixels(player, 1, 8).should == [nil, 0xEE, nil, 0xEE, nil, 0xEE, nil, 0xEE]
      end

      context 'two copies' do
        before do
          tia[NUSIZ0] = 1
          player.strobe
        end

        xit 'should draw the second copy of the player immediately' do          
          pixels(player, 17, 24).should == [nil, 0xEE, nil, 0xEE, nil, 0xEE, nil, 0xEE]
        end
      end
    end

  end
end
