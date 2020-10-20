SOUND:  {

sfx:{

    //lda #%10110110
    lda #%00011000
    sta $d404

    lda #%00001111
    sta $d418

    lda #$40
    sta $d405
    lda #%00001110
    sta $d406

    lda #$19
    sta $d401
    lda #$01
    sta $d400

    lda #$81
    sta $d404
    rts
}

}
