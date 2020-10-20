MAP:  {

draw_screen:{
    ldx #0
!:
    .for (var i=0; i<4;i++) {
        lda map_data+MAP_FRAME+(i * $FF),x
        sta $400+(i*$FF),x
        tay
        lda charset_attrib_data,y
        and #%00001111 // AND out colour
        sta $D800+(i * $FF),x
    }
    inx
    bne !-
    rts
}

copy_chars:{
    // note: was copy, now just point at $2800
    // --- means level can't be reloaded! Do copy yo.
    lda $d018
    and #%11110001
    ora #%00001010  // $2800
    sta $d018
    rts
}


get_cell:            {

    // out: a == cell value
    //      x == x cell
    //      y == y cell

 // Convert pos to X/Y cell locations
    clc
    ldy #0
    sty out_of_bounds
    lda TMP1 // X_LO
    asl
    lda TMP2 // X_HI
    rol
    bcc left_edge
msb_is_set:
    cmp #scr_RIGHT_EDGE_FROM_MSB
    bcc not_right_edge
right_edge:
    inc out_of_bounds
    // maybe todo: set out_of_bounds as bitflag for direction.
    // then can wrap in calling routine
    jmp has_msb
not_right_edge:
    cmp #scr_LEFT_HIDDEN_AREA
    bcc calc_x_cell
has_msb:
    ldy #1          // MSB is set
    jmp calc_x_cell
left_edge:
    cmp #scr_LEFT_HIDDEN_AREA
    bcs calc_x_cell
    inc out_of_bounds
calc_x_cell:
    sec
    sbc #scr_LEFT_HIDDEN_AREA
    lsr
    lsr
    lsr
    cpy #1          // MSB was set?
    bne !+
    adc #31         // MSB was set: add more tiles
!:
    sta TMP1 // X_CELL: re-set below
    tax

    // Y
    clc
    lda TMP3 // Y_LO
    asl
    lda TMP4 // Y_HI
    rol
    sec
    sbc #scr_TOP_HIDDEN_AREA

    lsr
    lsr
    lsr
    sta TMP2 // Y_CELL: re-set below
    tay

    lda out_of_bounds
    beq !+
    lda #TILES.tile_SOLID
    jmp load
!:
    lda SCREEN_ROW_LSB,y
    sta TMP3
    lda SCREEN_ROW_MSB,y
    sta TMP4
    txa
    tay

    // Check tile attrib
    lda (TMP3),y
    sta TMP3
    tax
    lda charset_attrib_data,x
load:
    ldx TMP1 // X_CELL
    ldy TMP2 // Y_CELL
done:
    rts
}

set_cell:{
    // in: a==cell value, x=x, y=y
    sta TMP3
    lda SCREEN_ROW_LSB,y
    sta TMP1
    lda SCREEN_ROW_MSB,y
    sta TMP2

    txa
    tay

    lda TMP3
    sta (TMP1),y
    //lda charset_attrib_data,y
    //and #%00001111  // AND out colour
    //sta $D800+(i * $FF),x
    rts
}

}
