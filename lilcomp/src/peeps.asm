PEEPS:  {

update:{

    ldx #NUM_PEEPS-1
!:
    lda p_sp,x
    bpl !pos+
    dec p_x_hi,x
!pos:
    adc p_x_lo,x
    sta p_x_lo,x
    bcc !nover+
    inc p_x_hi,x
!nover:
    lda p_x_hi,x
    cmp p_x_min,x
    bmi flip
    lda p_x_hi,x
    cmp p_x_max,x
    bpl flip
    jmp !done+
flip:
    clc
    lda p_sp,x
    eor #$ff
    adc #1
    sta p_sp,x
!done:
    dex
    bpl !-
    rts
}

}
