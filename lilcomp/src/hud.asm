HUD:    {

update:{
    lda stroke
    jsr UTILS.byte_to_decimal
    stx $409
    sta $40a

    lda shoot_power
    jsr UTILS.byte_to_decimal
    sty $415
    stx $416
    sta $417

    lda PLAYER.on_ladder
    jsr UTILS.byte_to_decimal
    sty $420
    stx $421
    sta $422

    rts
}

}
