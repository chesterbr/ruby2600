require 'spec_helper'

describe Ruby2600::Missile do

  let(:tia) { mock 'tia', :reg => Array.new(64, 0) }
  subject(:missile) { Ruby2600::Missile.new(tia, 0) }

  context 'missile 1' do
    subject(:missile1) { Ruby2600::Missile.new(tia, 1) }

    before do
      tia.reg[ENAM1] = 0
      tia.reg[COLUP0] = 0x00
      tia.reg[COLUP1] = 0xFF
      missile.counter.reset
      160.times { missile1.pixel }
    end

    it 'should never output if ENAM1 is disabled' do
      pixels(missile1, 1, 160).should_not include(0xFF)
    end

    it 'should generate some output if ENAM1 is enabled' do
      tia.reg[ENAM1] = rand(256) | 0b10
      pixels(missile1, 1, 160).should include(0xFF)
    end
  end

  describe 'pixel' do
    before do
      tia.reg[COLUP0] = rand(255) + 1
    end

    it 'should never output if ENAM0 is disabled' do
      tia.reg[ENAM0] = 0

      pixels(missile, 1, 300).should == Array.new(300)
    end

    it 'should generate some output if ENAM0 is enabled' do
      tia.reg[ENAM0] = rand(256) | 0b10

      pixels(missile, 1, 300).should include(tia.reg[COLUP0])
    end

    context 'drawing (strobe)' do
      let(:color) { [rand(255) + 1] }

      before do
        # Cleanup and pick a random position
        tia.reg[ENAM0] = 0
        rand(160).times { missile.pixel }

        # Preemptive strobe (to ensure we don't have retriggering leftovers)
        missile.counter.reset
        80.times { missile.pixel }

        # Setup
        tia.reg[ENAM0] = 0b10
        tia.reg[COLUP0] = color[0]
      end

      context 'one copy' do
        before do
          tia.reg[NUSIZ0] = 0
          missile.counter.reset
          4.times { missile.pixel } # 4-bit delay
        end

        it 'should not draw anything on current scanline' do
          pixels(missile, 1, 160).should == Array.new(160)
        end

        it 'should draw after a full scanline (160pixels) + 4-bit delay' do
          160.times { missile.pixel }
          pixels(missile, 1, 160).should == color + Array.new(159)
        end

        it 'should draw again on subsequent scanlines' do
          320.times { missile.pixel }
          10.times { pixels(missile, 1, 160).should == color + Array.new(159) }
        end
      end

      context 'two copies, close' do
        before do
          tia.reg[NUSIZ0] = 1
          missile.counter.reset
          4.times { missile.pixel }
        end

        it 'should only draw second copy on current scanline (after 4 bit delay)' do
          pixels(missile, 1, 24).should == Array.new(16) + color + Array.new(7)
        end

        it 'should draw both copies on subsequent scanlines' do
          160.times { missile.pixel }
          pixels(missile, 1, 24).should == color + Array.new(15) + color + Array.new(7)
        end
      end

      context 'two copies, medium' do
        before do
          tia.reg[NUSIZ0] = 2
          missile.counter.reset
          4.times { missile.pixel }
        end

        it 'should only draw second copy on current scanline (after 4 bit delay)' do
          pixels(missile, 1, 40).should == Array.new(32) + color + Array.new(7)
        end

        it 'should draw both copies on subsequent scanlines' do
          160.times { missile.pixel }
          pixels(missile, 1, 40).should == color + Array.new(7) + Array.new(24) + color + Array.new(7)
        end
      end

      context 'three copies, close' do
        before do
          tia.reg[NUSIZ0] = 3
          missile.counter.reset
          4.times { missile.pixel }
        end

        it 'should only draw second and third copy on current scanline (after 4 bit delay)' do
          pixels(missile, 1, 40).should == Array.new(16) + color + Array.new(7) + Array.new(8) + color + Array.new(7)
        end

        it 'should draw three copies on subsequent scanlines' do
          160.times { missile.pixel }
          pixels(missile, 1, 40).should == color + Array.new(7) + Array.new(8) + color + Array.new(7) + Array.new(8) + color + Array.new(7)
        end
      end

      context 'two copies, wide' do
        before do
          tia.reg[NUSIZ0] = 4
          missile.counter.reset
          4.times { missile.pixel }
        end

        it 'should only draw second copy on current scanline (after 4 bit delay)' do
          pixels(missile, 1, 72).should == Array.new(64) + color + Array.new(7)
        end

        it 'should draw both copies on subsequent scanlines' do
          160.times { missile.pixel }
          pixels(missile, 1, 72).should == color + Array.new(7) + Array.new(56) + color + Array.new(7)
        end
      end

      context 'three copies, medium' do
        before do
          tia.reg[NUSIZ0] = 6
          missile.counter.reset
          4.times { missile.pixel }
        end

        it 'should only draw second and third copy on current scanline (after 4 bit delay)' do
          pixels(missile, 1, 72).should == Array.new(32) + color + Array.new(7) + Array.new(24) + color + Array.new(7)
        end

        it 'should draw three copies on subsequent scanlines' do
          160.times { missile.pixel }
          pixels(missile, 1, 72).should == color + Array.new(7) + Array.new(24) + color + Array.new(7) + Array.new(24) + color + Array.new(7)
        end

        context '2x' do
          before { tia.reg[NUSIZ0] = 0b00010110 }

          it 'should draw 3 copies with size 2' do
            160.times { missile.pixel }
            pixels(missile, 1, 160).should == scanline_with_object(2, color[0], 3)
          end
        end

        context '4x' do
          before { tia.reg[NUSIZ0] = 0b00100110 }

          it 'should draw 3 copies with size 4' do
            160.times { missile.pixel }
            pixels(missile, 1, 160).should == scanline_with_object(4, color[0], 3)
          end
        end

        context '8x' do
          before { tia.reg[NUSIZ0] = 0b00110110 }

          it 'should draw 3 copies with size 8' do
            160.times { missile.pixel }
            pixels(missile, 1, 160).should == scanline_with_object(8, color[0], 3)
          end
        end
      end
    end
  end

  describe '#reset_to' do
    let(:player) { Ruby2600::Player.new(tia, 0) }

    before do
      rand(160).times { player.counter.tick }
    end

    it "should not affect the player's counter" do
      expect {
        missile.counter.reset_to player.counter
      }.to_not change { player.counter.value }
    end

    it "should set both objects to the same clock phase (i.e., same value without drifting)" do
      missile.counter.reset_to player.counter

      4.times do
        missile.counter.tick
        player.counter.tick

        missile.counter.value.should == player.counter.value
      end
    end
  end
end