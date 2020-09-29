            BasicUpstart2(entry)
entry:
                sei
// sync:
//                 cmp $d012
//                 bne *-3
//                 ldy #8
//                 sty $dc04
//                 dey
//                 bne *-1
//                 sty $dc05
//                 sta $dc03,y
//                 lda #$11
//                 cmp $d012
//                 sty $d015
//                 bne sync
                cli
                rts

scan:
                ldx #$31
                cpx $d012
                bne *-3

                lda $dc04               // timer A - jttters between 7 and 1
                clc
                adc #$ff-8
                eor #$ff
                //eor #$17                //7-A (0..6 in A)
                sta *+4                 // bpl jump addr
                bpl *+2
                cmp #$c9                // if a=1 cmp  (2 more cycles)
                cmp #$c9                // if a=3, cmp# 2 cycles
                bit $ea24               // if a=4,bit$ea2. a=5,bit #ea,a=6 nop

                stx $d020
                sty $d020

                jmp scan
