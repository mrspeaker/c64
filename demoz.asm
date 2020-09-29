            BasicUpstart2(entry)

entry:
                sei

                lda #0
                sta $d021
main:
                lda #0
                sta $d020

                lda #%11111111
                sta $D015
                lda #$60
                sta $D000
                sta $D001

bars:
                // wait for line
                lda #$70
!:
                cmp $d012
                bne !-

                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop

                ldy #52
line:
                lda colors,y
                sta $d020 // 6
                sta $d021 // 6

                // waste cycles
                ldx #$7
!:
                dex
                bne !-

                nop
                nop
                nop
                //nop
                //bit $fe

                dey
                bne line


                jsr bars

colors:
                .byte $0,$0,$6,$e,$6,$e,$e,$6,$e,$e,$e,$3
                .byte $e,$3,$3,$e,$3,$3,$3,$1,$3,$1,$1,$3
                .byte $1,1,1,3,1,1,3,1,3,3,3,$e
                .byte 3,3,$e,3,$e,$e,$e,6,$e,$e,6,$e
                .byte 6,6,6,0,0,0
