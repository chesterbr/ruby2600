require 'spec_helper'

describe Ruby2600::Player do

  let(:tia) { mock 'tia', :reg => Array.new(64, 0) }
  subject(:player) { Ruby2600::Player.new(tia, 0) }

  context 'player 1' do
    subject(:player1) { Ruby2600::Player.new(tia, 1) }

    before do
      tia.reg[GRP0] = 0x00
      tia.reg[COLUP0] = 0x00
      tia.reg[COLUP1] = 0xFF
      player1.counter.strobe
      160.times { player1.pixel }
    end

    it 'should not draw anything without GRP1' do
      pixels(player1, 1, 160).should_not include(0xFF)
    end

    it 'should draw if GRP1 is set' do
      tia.reg[GRP1] = 0xFF
      pixels(player1, 1, 160).should include(0xFF)
    end
  end

  describe 'pixel' do
    it 'should never output if GRP0 is all zeros' do
      tia.reg[GRP0] = 0
      300.times { player.pixel.should be_nil }
    end

    context 'drawing (strobe, NUSIZ0, REFP0)' do
      COLOR = 2 * (rand(127) + 1)
      PIXELS = [COLOR, COLOR, nil, nil, COLOR, nil, COLOR, nil]
      PIXELS_2X = PIXELS.map    { |p| [p, p] }.flatten
      PIXELS_4X = PIXELS_2X.map { |p| [p, p] }.flatten

      before do
        # Cleanup and pick a random position
        tia.reg[GRP0] = 0
        rand(160).times { player.pixel }

        # Preemptive strobe (to ensure we don't have retriggering leftovers)
        player.counter.strobe
        80.times { player.pixel }

        # Setup
        tia.reg[GRP0] = 0b11001010
        tia.reg[COLUP0] = COLOR
      end

      context 'one copy' do
        before do
          tia.reg[NUSIZ0] = 0
          player.counter.strobe
          5.times { player.pixel }
        end

        it 'should not draw anything on current scanline' do
          pixels(player, 1, 160).should == Array.new(160)
        end

        it 'should draw after a full scanline (160pixels) + 5-bit delay' do
          160.times { player.pixel }
          pixels(player, 1, 8).should == PIXELS
        end

        it 'should draw again on subsequent scanlines' do
          320.times { player.pixel }
          10.times { pixels(player, 1, 160).should == PIXELS + Array.new(152) }
        end
      end

      context 'two copies, close' do
        before do
          tia.reg[NUSIZ0] = 1
          player.counter.strobe
          5.times { player.pixel }
        end

        it 'should only draw second copy on current scanline (after 5 bit delay)' do
          pixels(player, 1, 24).should == Array.new(16) + PIXELS
        end

        it 'should draw both copies on subsequent scanlines' do
          160.times { player.pixel }
          pixels(player, 1, 24).should == PIXELS + Array.new(8) + PIXELS
        end
      end

      context 'two copies, medium' do
        before do
          tia.reg[NUSIZ0] = 2
          player.counter.strobe
          5.times { player.pixel }
        end

        it 'should only draw second copy on current scanline (after 5 bit delay)' do
          pixels(player, 1, 40).should == Array.new(32) + PIXELS
        end

        it 'should draw both copies on subsequent scanlines' do
          160.times { player.pixel }
          pixels(player, 1, 40).should == PIXELS + Array.new(24) + PIXELS
        end
      end

      context 'three copies, close' do
        before do
          tia.reg[NUSIZ0] = 3
          player.counter.strobe
          5.times { player.pixel }
        end

        it 'should only draw second and third copy on current scanline (after 5 bit delay)' do
          pixels(player, 1, 40).should == Array.new(16) + PIXELS + Array.new(8) + PIXELS
        end

        it 'should draw three copies on subsequent scanlines' do
          160.times { player.pixel }
          pixels(player, 1, 40).should == PIXELS + Array.new(8) + PIXELS + Array.new(8) + PIXELS
        end
      end

      context 'two copies, wide' do
        before do
          tia.reg[NUSIZ0] = 4
          player.counter.strobe
          5.times { player.pixel }
        end

        it 'should only draw second copy on current scanline (after 5 bit delay)' do
          pixels(player, 1, 72).should == Array.new(64) + PIXELS
        end

        it 'should draw both copies on subsequent scanlines' do
          160.times { player.pixel }
          pixels(player, 1, 72).should == PIXELS + Array.new(56) + PIXELS
        end
      end

      context 'one copy, double size' do
        before do
          tia.reg[NUSIZ0] = 5
          player.counter.strobe
          5.times { player.pixel }
        end

        it 'should not draw anything on current scanline' do
          pixels(player, 1, 160).should == Array.new(160)
        end

        it 'should draw on subsequent scanlines' do
          160.times { player.pixel }
          pixels(player, 1, 160).should == PIXELS_2X + Array.new(144)
        end
      end

      context 'three copies, medium' do
        before do
          tia.reg[NUSIZ0] = 6
          player.counter.strobe
          5.times { player.pixel }
        end

        it 'should only draw second and third copy on current scanline (after 5 bit delay)' do
          pixels(player, 1, 72).should == Array.new(32) + PIXELS + Array.new(24) + PIXELS
        end

        it 'should draw three copies on subsequent scanlines' do
          160.times { player.pixel }
          pixels(player, 1, 72).should == PIXELS + Array.new(24) + PIXELS + Array.new(24) + PIXELS
        end

        context 'with REFP0 set' do
          before { tia.reg[REFP0] = rand(256) | 0b1000 }

          it 'should reflect the drawing' do
            160.times { player.pixel }
            pixels(player, 1, 72).should == PIXELS.reverse + Array.new(24) + PIXELS.reverse + Array.new(24) + PIXELS.reverse
          end
        end
      end

      context 'one copy, quad size' do
        before do
          tia.reg[NUSIZ0] = 7
          player.counter.strobe
          5.times { player.pixel }
        end

        it 'should not draw anything on current scanline' do
          pixels(player, 1, 160).should == Array.new(160)
        end

        it 'should draw on subsequent scanlines' do
          160.times { player.pixel }
          pixels(player, 1, 160).should == PIXELS_4X + Array.new(128)
        end

        context 'with REFP0 set' do
          before { tia.reg[REFP0] = rand(256) | 0b1000 }

          it 'should reflect the drawing' do
            160.times { player.pixel }
            pixels(player, 1, 160).should == PIXELS_4X.reverse + Array.new(128)
          end
        end
      end

      context 'one copy, double size with missile size set' do
        before do
          tia.reg[NUSIZ0] = 0b00110101
          player.counter.strobe
          5.times { player.pixel }
        end

        it 'should not be affected (should draw on subsequent scanlines)' do
          160.times { player.pixel }
          pixels(player, 1, 160).should == PIXELS_2X + Array.new(144)
        end
      end

      pending 'HMOVE test (unless we make it on movable_object)'

      pending 'VDELPn test'

      pending 'dynamic change of GRPn/REFPn test'
    end
  end
end
