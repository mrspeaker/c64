UTILS:  {

byte_to_decimal:{
    //in: a = value
    //out: a=1s, x=10s, y=100s
    ldy #$2f
    ldx #$3a
    sec
!:  iny
    sbc #100
    bcs !-
!:  dex
    adc #10
    bmi !-
    adc #$2f
    rts
}

}
