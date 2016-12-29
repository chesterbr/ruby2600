require 'spec_helper'

describe Ruby2600::Missile do

  let(:tia) { double 'tia', :reg => Array.new(64, 0), :scanline_stage => :visible }
  subject(:missile) { Ruby2600::Missile.new(tia, 0) }

  context 'missile 1' do
    subject(:missile1) { Ruby2600::Missile.new(tia, 1) }

    before do
      tia.reg[ENAM1] = 0
      tia.reg[COLUP0] = 0x00
      tia.reg[COLUP1] = 0xFF
      missile.reset
      160.times { missile1.tick }
    end

    it 'nevers output if ENAM1 is disabled' do
      expect(pixels(missile1, 1, 160)).not_to include(0xFF)
    end

    it 'generates some output if ENAM1 is enabled' do
      tia.reg[ENAM1] = rand(256) | 0b10
      expect(pixels(missile1, 1, 160)).to include(0xFF)
    end
  end

  describe 'pixel' do
    before do
      tia.reg[COLUP0] = rand(255) + 1
    end

    it 'nevers output if ENAM0 is disabled' do
      tia.reg[ENAM0] = 0

      expect(pixels(missile, 1, 300)).to eq(Array.new(300))
    end

    it 'generates some output if ENAM0 is enabled' do
      tia.reg[ENAM0] = rand(256) | 0b10

      expect(pixels(missile, 1, 300)).to include(tia.reg[COLUP0])
    end

    context 'drawing (strobe)' do
      let(:color) { [rand(255) + 1] }

      before do
        # Cleanup and pick a random position
        tia.reg[ENAM0] = 0
        rand(160).times { missile.tick }

        # Preemptive strobe (to ensure we don't have retriggering leftovers)
        missile.reset
        80.times { missile.tick }

        # Setup
        tia.reg[ENAM0] = 0b10
        tia.reg[COLUP0] = color[0]
      end

      context 'one copy' do
        before do
          tia.reg[NUSIZ0] = 0
          missile.reset
          4.times { missile.tick } # 4-bit delay
        end

        it 'nots draw anything on current scanline' do
          expect(pixels(missile, 1, 160)).to eq(Array.new(160))
        end

        it 'draws after a full scanline (160pixels) + 4-bit delay' do
          160.times { missile.tick }
          expect(pixels(missile, 1, 160)).to eq(color + Array.new(159))
        end

        it 'draws again on subsequent scanlines' do
          320.times { missile.tick }
          10.times { expect(pixels(missile, 1, 160)).to eq(color + Array.new(159)) }
        end
      end

      context 'two copies, close' do
        before do
          tia.reg[NUSIZ0] = 1
          missile.reset
          4.times { missile.tick }
        end

        it 'onlys draw second copy on current scanline (after 4 bit delay)' do
          expect(pixels(missile, 1, 24)).to eq(Array.new(16) + color + Array.new(7))
        end

        it 'draws both copies on subsequent scanlines' do
          160.times { missile.tick }
          expect(pixels(missile, 1, 24)).to eq(color + Array.new(15) + color + Array.new(7))
        end
      end

      context 'two copies, medium' do
        before do
          tia.reg[NUSIZ0] = 2
          missile.reset
          4.times { missile.tick }
        end

        it 'onlys draw second copy on current scanline (after 4 bit delay)' do
          expect(pixels(missile, 1, 40)).to eq(Array.new(32) + color + Array.new(7))
        end

        it 'draws both copies on subsequent scanlines' do
          160.times { missile.tick }
          expect(pixels(missile, 1, 40)).to eq(color + Array.new(7) + Array.new(24) + color + Array.new(7))
        end
      end

      context 'three copies, close' do
        before do
          tia.reg[NUSIZ0] = 3
          missile.reset
          4.times { missile.tick }
        end

        it 'onlys draw second and third copy on current scanline (after 4 bit delay)' do
          expect(pixels(missile, 1, 40)).to eq(Array.new(16) + color + Array.new(7) + Array.new(8) + color + Array.new(7))
        end

        it 'draws three copies on subsequent scanlines' do
          160.times { missile.tick }
          expect(pixels(missile, 1, 40)).to eq(color + Array.new(7) + Array.new(8) + color + Array.new(7) + Array.new(8) + color + Array.new(7))
        end
      end

      context 'two copies, wide' do
        before do
          tia.reg[NUSIZ0] = 4
          missile.reset
          4.times { missile.tick }
        end

        it 'onlys draw second copy on current scanline (after 4 bit delay)' do
          expect(pixels(missile, 1, 72)).to eq(Array.new(64) + color + Array.new(7))
        end

        it 'draws both copies on subsequent scanlines' do
          160.times { missile.tick }
          expect(pixels(missile, 1, 72)).to eq(color + Array.new(7) + Array.new(56) + color + Array.new(7))
        end
      end

      context 'three copies, medium' do
        before do
          tia.reg[NUSIZ0] = 6
          missile.reset
          4.times { missile.tick }
        end

        it 'onlys draw second and third copy on current scanline (after 4 bit delay)' do
          expect(pixels(missile, 1, 72)).to eq(Array.new(32) + color + Array.new(7) + Array.new(24) + color + Array.new(7))
        end

        it 'draws three copies on subsequent scanlines' do
          160.times { missile.tick }
          expect(pixels(missile, 1, 72)).to eq(color + Array.new(7) + Array.new(24) + color + Array.new(7) + Array.new(24) + color + Array.new(7))
        end

        context '2x' do
          before { tia.reg[NUSIZ0] = 0b00010110 }

          it 'draws 3 copies with size 2' do
            160.times { missile.tick }
            expect(pixels(missile, 1, 160)).to eq(scanline_with_object(2, color[0], 3))
          end
        end

        context '4x' do
          before { tia.reg[NUSIZ0] = 0b00100110 }

          it 'draws 3 copies with size 4' do
            160.times { missile.tick }
            expect(pixels(missile, 1, 160)).to eq(scanline_with_object(4, color[0], 3))
          end
        end

        context '8x' do
          before { tia.reg[NUSIZ0] = 0b00110110 }

          it 'draws 3 copies with size 8' do
            160.times { missile.tick }
            expect(pixels(missile, 1, 160)).to eq(scanline_with_object(8, color[0], 3))
          end
        end
      end
    end
  end

  describe '#reset_to' do
    let(:player) { Ruby2600::Player.new(tia, 0) }

    before do
      rand(160).times { player.tick }
    end

    it "nots affect the player's counter" do
      expect {
        missile.reset_to player
      }.to_not change { player.value }
    end

    it "sets both objects to the same clock phase (i.e., same value without drifting)" do
      missile.reset_to player

      4.times do
        missile.tick
        player.tick

        expect(missile.value).to eq(player.value)
      end
    end
  end
end
