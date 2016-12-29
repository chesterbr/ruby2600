require 'spec_helper'

describe Ruby2600::Player do

  let(:tia) { double 'tia', :reg => Array.new(64, 0), :scanline_stage => :visible }
  subject(:player) { Ruby2600::Player.new(tia, 0) }

  context 'player 1' do
    subject(:player1) { Ruby2600::Player.new(tia, 1) }

    before do
      tia.reg[GRP0] = 0x00
      tia.reg[COLUP0] = 0x00
      tia.reg[COLUP1] = 0xFF
      player1.reset
      160.times { player1.tick }
    end

    it 'does not draw anything without GRP1' do
      expect(pixels(player1, 1, 160)).not_to include(0xFF)
    end

    it 'draws if GRP1 is set' do
      tia.reg[GRP1] = 0xFF
      expect(pixels(player1, 1, 160)).to include(0xFF)
    end
  end

  describe 'pixel' do
    it 'never outputs if GRP0 is all zeros' do
      tia.reg[GRP0] = 0
      300.times do
        player.tick
        expect(player.pixel).to be_nil
      end
    end

    context 'drawing (strobe, NUSIZ0, REFP0)' do
      COLOR = 2 * (rand(127) + 1)
      PIXELS = [COLOR, COLOR, nil, nil, COLOR, nil, COLOR, nil]
      PIXELS_2X = PIXELS.map    { |p| [p, p] }.flatten
      PIXELS_4X = PIXELS_2X.map { |p| [p, p] }.flatten

      before do
        # Cleanup and pick a random position
        tia.reg[GRP0] = 0
        rand(160).times { player.tick }

        # Preemptive strobe (to ensure we don't have retriggering leftovers)
        player.reset
        80.times { player.tick }

        # Setup
        tia.reg[GRP0] = 0b11001010
        tia.reg[COLUP0] = COLOR
      end

      context 'one copy' do
        before do
          tia.reg[NUSIZ0] = 0
          player.reset
          5.times { player.tick }
        end

        it 'does not draw anything on current scanline' do
          expect(pixels(player, 1, 160)).to eq(Array.new(160))
        end

        it 'draws after a full scanline (160pixels) + 5-bit delay' do
          160.times { player.tick }
          expect(pixels(player, 1, 8)).to eq(PIXELS)
        end

        it 'draws again on subsequent scanlines' do
          320.times { player.tick }
          10.times { expect(pixels(player, 1, 160)).to eq(PIXELS + Array.new(152)) }
        end
      end

      context 'two copies, close' do
        before do
          tia.reg[NUSIZ0] = 1
          player.reset
          5.times { player.tick }
        end

        it 'onlys draw second copy on current scanline (after 5 bit delay)' do
          expect(pixels(player, 1, 24)).to eq(Array.new(16) + PIXELS)
        end

        it 'draws both copies on subsequent scanlines' do
          160.times { player.tick }
          expect(pixels(player, 1, 24)).to eq(PIXELS + Array.new(8) + PIXELS)
        end
      end

      context 'two copies, medium' do
        before do
          tia.reg[NUSIZ0] = 2
          player.reset
          5.times { player.tick }
        end

        it 'onlys draw second copy on current scanline (after 5 bit delay)' do
          expect(pixels(player, 1, 40)).to eq(Array.new(32) + PIXELS)
        end

        it 'draws both copies on subsequent scanlines' do
          160.times { player.tick }
          expect(pixels(player, 1, 40)).to eq(PIXELS + Array.new(24) + PIXELS)
        end
      end

      context 'three copies, close' do
        before do
          tia.reg[NUSIZ0] = 3
          player.reset
          5.times { player.tick }
        end

        it 'onlys draw second and third copy on current scanline (after 5 bit delay)' do
          expect(pixels(player, 1, 40)).to eq(Array.new(16) + PIXELS + Array.new(8) + PIXELS)
        end

        it 'draws three copies on subsequent scanlines' do
          160.times { player.tick }
          expect(pixels(player, 1, 40)).to eq(PIXELS + Array.new(8) + PIXELS + Array.new(8) + PIXELS)
        end
      end

      context 'two copies, wide' do
        before do
          tia.reg[NUSIZ0] = 4
          player.reset
          5.times { player.tick }
        end

        it 'onlys draw second copy on current scanline (after 5 bit delay)' do
          expect(pixels(player, 1, 72)).to eq(Array.new(64) + PIXELS)
        end

        it 'draws both copies on subsequent scanlines' do
          160.times { player.tick }
          expect(pixels(player, 1, 72)).to eq(PIXELS + Array.new(56) + PIXELS)
        end
      end

      context 'one copy, double size' do
        before do
          tia.reg[NUSIZ0] = 5
          player.reset
          5.times { player.tick }
        end

        it 'does not draw anything on current scanline' do
          expect(pixels(player, 1, 160)).to eq(Array.new(160))
        end

        it 'draws on subsequent scanlines' do
          160.times { player.tick }
          expect(pixels(player, 1, 160)).to eq(PIXELS_2X + Array.new(144))
        end
      end

      context 'three copies, medium' do
        before do
          tia.reg[NUSIZ0] = 6
          player.reset
          5.times { player.tick }
        end

        it 'onlys draw second and third copy on current scanline (after 5 bit delay)' do
          expect(pixels(player, 1, 72)).to eq(Array.new(32) + PIXELS + Array.new(24) + PIXELS)
        end

        it 'draws three copies on subsequent scanlines' do
          160.times { player.tick }
          expect(pixels(player, 1, 72)).to eq(PIXELS + Array.new(24) + PIXELS + Array.new(24) + PIXELS)
        end

        context 'with REFP0 set' do
          before { tia.reg[REFP0] = rand(256) | 0b1000 }

          it 'reflects the drawing' do
            160.times { player.tick }
            expect(pixels(player, 1, 72)).to eq(PIXELS.reverse + Array.new(24) + PIXELS.reverse + Array.new(24) + PIXELS.reverse)
          end
        end
      end

      context 'one copy, quad size' do
        before do
          tia.reg[NUSIZ0] = 7
          player.reset
          5.times { player.tick }
        end

        it 'does not draw anything on current scanline' do
          expect(pixels(player, 1, 160)).to eq(Array.new(160))
        end

        it 'draws on subsequent scanlines' do
          160.times { player.tick }
          expect(pixels(player, 1, 160)).to eq(PIXELS_4X + Array.new(128))
        end

        context 'with REFP0 set' do
          before { tia.reg[REFP0] = rand(256) | 0b1000 }

          it 'reflects the drawing' do
            160.times { player.tick }
            expect(pixels(player, 1, 160)).to eq(PIXELS_4X.reverse + Array.new(128))
          end
        end
      end

      context 'one copy, double size with missile size set' do
        before do
          tia.reg[NUSIZ0] = 0b00110101
          player.reset
          5.times { player.tick }
        end

        it 'does not be affected (should draw on subsequent scanlines)' do
          160.times { player.tick }
          expect(pixels(player, 1, 160)).to eq(PIXELS_2X + Array.new(144))
        end
      end

      skip 'VDELPn test'

      skip 'dynamic change of GRPn/REFPn test'
    end
  end
end
