;
; diagonal.asm
;
; A test program that does a continous HMOV which results in a
; diagonal (for ruby2600 tests)
; This is free source code (see below). Build it with DASM
; (http://dasm-dillon.sourceforge.net/), by running:
;
;   dasm diagonal.asm -diagonal.bin -f3
;

    PROCESSOR 6502
    INCLUDE "vcs.h"

    ORG $F000

StartFrame:
    lda #%00000010
    sta VSYNC
    REPEAT 3
        sta WSYNC
    REPEND
    lda #0
    sta VSYNC

PreparePlayfield:
    lda #$02
    sta ENABL
    lda #$00
    sta ENAM0
    sta ENAM1    
    sta GRP1
    sta COLUBK
    sta PF0
    sta PF1
    sta PF2
    sta NUSIZ0
    sta REFP0
    lda #$F0
    sta HMBL
    sta HMP0
    lda #$FF
    sta COLUPF
    lda #$C5
    sta GRP0
    lda #$44
    sta COLUP0
    lda #$30
    sta CTRLPF
    ldx #0
    sta WSYNC
    REPEAT 32
        nop
    REPEND
    sta RESBL
    REPEAT 19
        nop
    REPEND
    sta RESP0
    REPEAT 35
        sta WSYNC
    REPEND
    lda #0
    sta VBLANK

Scanline:
    sta HMOVE
    sta WSYNC
    inx
    cpx #191
    bne Scanline

Overscan:
    lda #%01000010
    sta VBLANK      ;
    REPEAT 30
        sta WSYNC
    REPEND
    jmp StartFrame


    ORG $FFFA

    .WORD StartFrame
    .WORD StartFrame
    .WORD StartFrame

    END

;
; Copyright 2011-2013 Carlos Duarte do Nascimento (Chester). All rights reserved.
;
; Redistribution and use in source and binary forms, with or without modification, are
; permitted provided that the following conditions are met:
;
;    1. Redistributions of source code must retain the above copyright notice, this list of
;       conditions and the following disclaimer.
;
;    2. Redistributions in binary form must reproduce the above copyright notice, this list
;       of conditions and the following disclaimer in the documentation and/or other materials
;       provided with the distribution.
;
; THIS SOFTWARE IS PROVIDED BY CHESTER ''AS IS'' AND ANY EXPRESS OR IMPLIED
; WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
; FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> OR
; CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
; SERVICES;  LOSS OF USE, DATA, OR PROFITS;  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
; ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
; NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
; ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
; The views and conclusions contained in the software and documentation are those of the
; authors and should not be interpreted as representing official policies, either expressed
; or implied, of Chester.
;

