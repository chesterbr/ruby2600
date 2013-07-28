require 'spec_helper'

describe 'vertical delay' do
  subject(:tia) do
    tia = Ruby2600::TIA.new
    tia.cpu = mock('cpu', :tick => nil, :halted= => nil)
    tia.riot = mock('riot', :tick => nil)
    tia.scanline
    0x3F.downto(0) { |reg| tia[reg] = 0 }
    tia.scanline
    tia
  end

  def grp_on_scanline
    tia.scanline[5..12].join.to_i(2)
  end

  def ball_on_scanline
    tia.scanline[4]
  end

  context 'VDELP0' do
    before do
      tia[COLUP0] = 0x01
      tia[RESP0] = rand(256)
      tia.scanline

      # Old register = AA, new register = BB
      tia[GRP0] = 0xAA
      tia[GRP1] = rand(256)
      tia[GRP0] = 0xBB
    end

    it "should use new player by default" do
      grp_on_scanline.should == 0xBB
    end

    it "should use old player if VDELP0 bit 0 is set" do
      tia[VDELP0] = rand(256) | 1
      grp_on_scanline.should == 0xAA
    end
  end

  context 'VDELP1' do
    before do
      tia[COLUP1] = 0x01
      tia[RESP1] = rand(256)
      tia.scanline

      # Old register = AA, new register = BB
      tia[GRP1] = 0xAA
      tia[GRP0] = rand(256)
      tia[GRP1] = 0xBB
    end

    it "should use new player by default" do
      grp_on_scanline.should == 0xBB
    end

    it "should use old player if VDELP0 bit 0 is set" do
      tia[VDELP1] = rand(256) | 1
      grp_on_scanline.should == 0xAA
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
      puts tia.scanline.to_s
      ball_on_scanline.should_not == 0x22
    end

    it "should use old register (enabled) if VDELP0 bit 0 is set" do
      tia[VDELBL] = rand(256) & 1
      puts tia.scanline.to_s
      ball_on_scanline.should == 0x22
    end
  end
end
