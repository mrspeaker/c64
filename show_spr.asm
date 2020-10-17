        *=$801
        .byte 11,8,0,0,$9e,$32,$30,$36,$31,0,0,0 //sys2061

        lda #7
        sta $d015

        lda #24     // x
        sta $d000

        lda #50     // y
        sta $d001
        sta $d003
        sta $d005

        lda #0
        sta $d002
        lda #87
        sta $d004

        lda #%0110
        sta $d010

        lda #$340/64
        sta $7f8
        sta $7f9
        sta $7fa

        lda #128
        ldx #64
!:
        sta $340,x
        dex
        bpl !-

        ldx #0
!:
        lda msg,x
        beq done
        sta $400+[40*3],x
        lda #32
        sta $400+[40],x
        inx
        jmp !-
done:
        rts

msg:    .text "start:24              msb:256    end:+88"
        .byte 0
