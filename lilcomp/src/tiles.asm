TILES:  {

    .label tile_SOLID  = %00010000
    .label tile_HOLE   = %00100000
    .label tile_PICKUP = %00110000
    .label tile_LADDER = %01000000

    .label tile_EMPTY_ID = 32

tile_anim_counter:.byte 0
tile_anim_counter2: .byte 0

animate:    {
            lda tile_anim_counter
            clc
            adc #40
            sta tile_anim_counter
            bcc !+

    // water
            ldy ADDR_CHARSET_DATA+(87*8)+7
            ldx #6
rot_water:
            lda ADDR_CHARSET_DATA+(87*8),x
            sta ADDR_CHARSET_DATA+(87*8)+1,x
            dex
            bpl rot_water
            sty ADDR_CHARSET_DATA+(87*8)

    // air
            ldy ADDR_CHARSET_DATA+[31*8]
            ldx #0
rot_air:
            lda ADDR_CHARSET_DATA+[31*8]+1,x
            sta ADDR_CHARSET_DATA+[31*8],x
            inx
            txa
            cmp #7
            bmi rot_air
            sty ADDR_CHARSET_DATA+[31*8]+7


            ldx #0
rot_right:
            lda ADDR_CHARSET_DATA+[77*8],x
            tay
            ror
            tya
            ror
            sta ADDR_CHARSET_DATA+[77*8],x

            inx
            txa
            cmp #7
            bmi rot_right

!:

            clc
            lda tile_anim_counter2
            adc #3
            sta tile_anim_counter2
            bcc !+
            // next timer.
            jsr toggle_blocks
!:
            rts
}

toggle_blocks:{
            ldy #35
            lda charset_attrib_data,y
            eor #%00010000
            sta charset_attrib_data,y

            ldy #7
!:
            lda ADDR_CHARSET_DATA+[35*8],y
            eor #$ff
            sta ADDR_CHARSET_DATA+[35*8],y
            dey
            bpl !-
            rts
}

}
