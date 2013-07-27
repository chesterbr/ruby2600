require 'spec_helper'

describe 'vertical delay registers' do
  let(:tia) do
    Ruby2600::TIA.new.tap do |tia|
      tia.cpu  = mock('cpu',  :tick => nil, :halted= => nil)
      tia.riot = mock('riot', :tick => nil)
    end
  end

  def grp_on_scanline
    tia.scanline[5..12].join.to_i(2)
  end

  def ball_on_scanline
    tia.scanline[0]
  end

  before do
    0.upto(63) { |i| tia[i] = 0 }
    tia.scanline
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
      tia[COLUBK] = 0x11
      tia[COLUPF] = 0x22
      tia[RESBL] = rand(256)
      tia.scanline # FIXME remove and should work

      # Old register = enable ball, new register = disable ball
      tia[GRP0] = 0b10
      tia[GRP1] = rand(256)
      tia[GRP0] = 0b00
    end

    xit "should use new register (disabled => BK color) by default" do
      ball_on_scanline.should == 0x11
    end

    xit "should use old register (enabled => PF color) if VDELP0 bit 0 is set" do
      tia[VDELP0] = rand(256) | 1
      ball_on_scanline.should == 0x22
    end
  end
end
