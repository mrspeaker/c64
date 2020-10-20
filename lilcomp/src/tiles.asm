TILES:  {

    .label tile_SOLID  = %00010000
    .label tile_HOLE   = %00100000
    .label tile_PICKUP = %00110000
    .label tile_LADDER = %01000000

    .label tile_EMPTY_ID = 32

tile_anim_counter:.byte 0

animate:    {
            lda tile_anim_counter
            clc
            adc #40
            sta tile_anim_counter
            bcc !+

    // water
            ldy ADDR_CHARSET_DATA+(87*8)+7
            ldx #6
rot:
            lda ADDR_CHARSET_DATA+(87*8),x
            sta ADDR_CHARSET_DATA+(87*8)+1,x
            dex
            bpl rot
            sty ADDR_CHARSET_DATA+(87*8)

    // air
            ldy ADDR_CHARSET_DATA+[31*8]
            ldx #0
rot2:
            lda ADDR_CHARSET_DATA+[31*8]+1,x
            sta ADDR_CHARSET_DATA+[31*8],x
            inx
            txa
            cmp #7
            bmi rot2
            sty ADDR_CHARSET_DATA+[31*8]+7

!:
            rts
}

}
