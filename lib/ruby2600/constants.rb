module Ruby2600
  module Constants

    # TIA writable registers

    VSYNC  = 0x00
    VBLANK = 0x01
    WSYNC  = 0x02
    RSYNC  = 0x03
    NUSIZ0 = 0x04
    NUSIZ1 = 0x05
    COLUP0 = 0x06
    COLUP1 = 0x07
    COLUPF = 0x08
    COLUBK = 0x09
    CTRLPF = 0x0A
    REFP0  = 0x0B
    REFP1  = 0x0C
    PF0    = 0x0D
    PF1    = 0x0E
    PF2    = 0x0F
    RESP0  = 0x10
    POSH2  = 0x11
    RESP1  = 0x11
    RESM0  = 0x12
    RESM1  = 0x13
    RESBL  = 0x14
    AUDC0  = 0x15
    AUDC1  = 0x16
    AUDF0  = 0x17
    AUDF1  = 0x18
    AUDV0  = 0x19
    AUDV1  = 0x1A
    GRP0   = 0x1B
    GRP1   = 0x1C
    ENAM0  = 0x1D
    ENAM1  = 0x1E
    ENABL  = 0x1F
    HMP0   = 0x20
    HMP1   = 0x21
    HMM0   = 0x22
    HMM1   = 0x23
    HMBL   = 0x24
    VDELP0 = 0x25
    VDELP1 = 0x26
    VDELBL = 0x27
    RESMP0 = 0x28
    RESMP1 = 0x29
    HMOVE  = 0x2A
    HMCLR  = 0x2B
    CXCLR  = 0x2C

    # TIA readable registers
    # (using lower mirror (0x0n) instead of "traditional" (0x3n)
    # to match Ruby2600::Bus mirroring translation)

    CXM0P  = 0x00
    CXM1P  = 0x01
    CXP0FB = 0x02
    CXP1FB = 0x03
    CXM0FB = 0x04
    CXM1FB = 0x05
    CXBLPF = 0x06
    CXPPMM = 0x07
    INPT0  = 0x08
    INPT1  = 0x09
    INPT2  = 0x0A
    INPT3  = 0x0B
    INPT4  = 0x0C
    INPT5  = 0x0D

    # RIOT

    SWCHA   = 0x0280
    SWACNT  = 0x0281
    SWCHB   = 0x0282
    SWBCNT  = 0x0283
    INTIM   = 0x0284
    INSTAT  = 0x0285
    TIM1T   = 0x0294
    TIM8T   = 0x0295
    TIM64T  = 0x0296
    T1024T  = 0x0297
  end
end
