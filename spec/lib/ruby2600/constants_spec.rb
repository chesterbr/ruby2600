require 'spec_helper'

# Testing constants may sound nonsensical, but we must be 100% sure that
# their addresses (used by RIOT and TIA classes) match the mapping on Bus,
# guaranteeing that chips will work regardless of the mirror used by games

describe Ruby2600::Constants do
  include Ruby2600::Constants

  it 'should use $00-$3F mirror in all TIA constants' do
    [
      VSYNC, VBLANK, WSYNC, RSYNC, NUSIZ0, NUSIZ1, COLUP0, COLUP1, COLUPF,
      COLUBK, CTRLPF, REFP0, REFP1, PF0, PF1, PF2, RESP0, RESP1,
      RESM0, RESM1, RESBL, AUDC0, AUDC1, AUDF0, AUDF1, AUDV0, AUDV1,
      GRP0, GRP1, ENAM0, ENAM1, ENABL, HMP0, HMP1, HMM0, HMM1, HMBL,
      VDELP0, VDELP1, VDELBL, RESMP0, RESMP1, HMOVE, HMCLR, CXCLR,
      CXM0P, CXM1P, CXP0FB, CXP1FB, CXM0FB, CXM1FB, CXBLPF, CXPPMM,
      INPT0, INPT1, INPT2, INPT3, INPT4, INPT5
    ].each { |reg| reg.should be <= 0x3F }
  end

  it 'should use $0280-$029x mirror in al RIOT constants' do
    [
      SWCHA, SWACNT, SWCHB, SWBCNT, INTIM, INSTAT, TIM1T, TIM8T, TIM64T, T1024T
    ].each do |reg|
      reg.should be >= 0x280
      reg.should be <= 0x29F
    end
  end
end
