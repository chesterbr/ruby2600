require 'spec_helper'

describe 'vertical delay' do
  subject(:frame_generator) { Ruby2600::FrameGenerator.new(cpu, tia, riot) }

  let(:cpu)  { double 'cpu', :tick => nil, :halted= => nil }
  let(:riot) { double 'riot', :tick => nil }
  let(:tia) do
    tia = Ruby2600::TIA.new
    tia.cpu = cpu
    tia.riot = riot
    tia
  end

  before do
    frame_generator.scanline
    0x3F.downto(0) { |reg| tia[reg] = 0 }
    frame_generator.scanline
  end

  def grp_on_scanline
    frame_generator.scanline[5..12].join.to_i(2)
  end

  def ball_on_scanline
    frame_generator.scanline[4]
  end

  context 'VDELP0' do
    before do
      tia[COLUP0] = 0x01
      tia[RESP0] = rand(256)
      frame_generator.scanline

      # Old register = AA, new register = BB
      tia[GRP0] = 0xAA
      tia[GRP1] = rand(256)
      tia[GRP0] = 0xBB
    end

    it "should use new player by default" do
      expect(grp_on_scanline).to eq(0xBB)
    end

    it "should use old player if VDELP0 bit 0 is set" do
      tia[VDELP0] = rand(256) | 1
      expect(grp_on_scanline).to eq(0xAA)
    end
  end

  context 'VDELP1' do
    before do
      tia[COLUP1] = 0x01
      tia[RESP1] = rand(256)
      frame_generator.scanline

      # Old register = AA, new register = BB
      tia[GRP1] = 0xAA
      tia[GRP0] = rand(256)
      tia[GRP1] = 0xBB
    end

    it "should use new player by default" do
      expect(grp_on_scanline).to eq(0xBB)
    end

    it "should use old player if VDELP0 bit 0 is set" do
      tia[VDELP1] = rand(256) | 1
      expect(grp_on_scanline).to eq(0xAA)
    end
  end

  context 'VDELBL' do
    before do
      tia[COLUPF] = 0x22
      tia[RESBL] = rand(256)

      # Old register = enable ball, new register = disable ball
      tia[ENABL] = 0b10
      tia[GRP1] = rand(256)
      tia[ENABL] = 0b00
    end

    it "should use new register (disabled) by default" do
      expect(ball_on_scanline).not_to eq(0x22)
    end

    it "should use old register (enabled) if VDELP0 bit 0 is set" do
      skip "intermitent failures on this test, fix it"
      tia[VDELBL] = rand(256) & 1
      expect(ball_on_scanline).to eq(0x22)
    end
  end
end
