            BasicUpstart2(main)

main:
                jsr init
_loop:
                jsr characters
                jsr printm
                jmp _loop

init:
                lda #$0
                sta $d020
                sta $d021
                rts

characters:
                // rnd pos
                lda $d012
                eor $dc04
                sbc $dc05
                tax
                // rnd char
                eor $dc04

                sta $400,x
                sta $500,x
                sta $600,x
                sta $6e8,x

                sta $d800,x
                sta $d900,x
                sta $da00,x
                sta $dae8,x
                rts

printm:
                ldx #0
_pr:
                lda msg,x
                beq _pr_d
                sta $400+40*10,x
                lda msg_col,x
                sta $d800+40*10,x
                inx
                jmp _pr
_pr_d:          rts


msg:            .text "                                        "
                .text "            mr speaker rulez!           "
                .text "                                        "
                .byte 0

msg_col:        .byte 1,1,1,1,1,1,1,1,1,1,9,9,2,2,8,8,$a,$a,$f,$f
                .byte $f,$f,$a,$a,8,8,2,2,9,9,1,1,1,1,1,1,1,1,1,1
                .byte 1,1,1,1,1,1,1,1,1,1,9,9,2,2,8,8,$a,$a,$f,$f
                .byte $f,$f,$a,$a,8,8,2,2,9,9,1,1,1,1,1,1,1,1,1,1
                .byte 1,1,1,1,1,1,1,1,1,1,9,9,2,2,8,8,$a,$a,$f,$f
                .byte $f,$f,$a,$a,8,8,2,2,9,9,1,1,1,1,1,1,1,1,1,1
