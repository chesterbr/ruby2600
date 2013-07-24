require 'spec_helper'

describe Ruby2600::Player do

  let(:tia) { Array.new(32, 0) }
  subject(:player) { Ruby2600::Player.new(tia, 0) }

  def pixels(player, first, last)
    (first-1).times { player.pixel }
    (0..(last - first)).map { player.pixel }
  end

  context 'player 1' do
    subject(:player1) { Ruby2600::Player.new(tia, 1) }

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

    context 'player strobing' do
      COLOR = 2 * (rand(127) + 1)
      PATTERN_PIXELS = [COLOR, COLOR, nil, nil, COLOR, nil, COLOR, nil]
      PATTERN_BITS   = 0b11001010

      before do
        tia[GRP0]   = PATTERN_BITS
        tia[NUSIZ0] = 0                    # no repetition
        tia[COLUP0] = COLOR
        rand(160).times { player.pixel }   # arbitrary screen position
        player.strobe
      end

      it 'should output the player after a full scanline (160pixels) + 5-bit delay' do
        # Player is drawn on next scanline (160 pixels), delayed by 5 pixels
        165.times { player.pixel }
        pixels(player, 1, 8).should == PATTERN_PIXELS
      end

      xit 'should draw player again on second-after-current scanline' do
        325.times { player.pixel }
        pixels(player, 1, 8).should == PATTERN_PIXELS
      end

      it 'should draw player on third-after-current scanline' do
        485.times { player.pixel }
        pixels(player, 1, 8).should == PATTERN_PIXELS
      end

      context 'two copies' do
        before do
          tia[NUSIZ0] = 1
          player.strobe
        end

        it 'should draw the second copy of the player on *current* scanline (after 5 bit delay)' do
          5.times { player.pixel }
          pixels(player, 17, 24).should == PATTERN_PIXELS
        end
      end
    end

  end
end
