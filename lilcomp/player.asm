PLAYER: {

    .const WALK_SPEED = 80

    x_lo: .byte $0
    x_hi: .byte $0
    y_lo: .byte $0
    y_hi: .byte $0

    init: {

  }

      //======================
walking: {
    //======================
    lda #0
    sta player_moved
    lda input_state
wup:lsr
//     bcs wdown
//     tax
//     sec
//     lda b_y_lo
//     sbc #st_walk_SPEED
//     sta b_y_lo
//     bcs !+
//     dec b_y_hi
// !:  txa
wdown:  lsr
//     bcs wleft
//     tax
//     clc
//     lda b_y_lo
//     adc #st_walk_SPEED
//     sta b_y_lo
//     bcc !+
//     inc b_y_hi
// !:  txa
wleft:  lsr
    bcs wright
    tax
    lda #-WALK_SPEED
    bpl !pos+
    dec b_x_hi
!pos:
    adc b_x_lo
    sta b_x_lo
    bcc !nover+
    inc b_x_hi
!nover:
    dec player_moved
!:  txa
wright: lsr
    bcs wfire
    tax
    lda #WALK_SPEED
    bpl !pos+
    dec b_x_hi
!pos:
    adc b_x_lo
    sta b_x_lo
    bcc !nover+
    inc b_x_hi
!nover:
    inc player_moved
!:  txa
wfire:  lsr
    bcs still_walking
    lda #state_WAIT_AIM_FIRE
    sta state
still_walking:
    lda player_moved
    beq !done+
    jsr walk_collision
!done:
    rts
}

walk_collision:{
    // Check cell left/right
    lda b_x_lo
    sta TMP1
    lda b_x_hi
    sta TMP2
    lda b_y_lo
    sta TMP3
    lda b_y_hi
    sta TMP4
    jsr get_cell
    and #tile_SOLID
    bne collide

    // Check cell under
    lda b_x_lo
    sta TMP1
    lda b_x_hi
    sta TMP2
    lda b_y_lo
    sta TMP3
    clc
    lda b_y_hi
    adc #1
    sta TMP4
    jsr get_cell
    and #tile_SOLID
    bne safe

at_the_edge:
/*
Testing idea:

instead of being stuck on platform, can walk off the edges.
This make the game more fast/action-y - but will take the
focus off the shooting part. Need to figure out some levels
and see if it needs it.

    //clc
    lda player_moved
    bpl pos
    // TODO: proper 16bit add!
    dec acc_x_hi
    dec acc_x_hi
    dec acc_x_hi
    jmp !+
pos:
    inc acc_x_hi
    inc acc_x_hi
    inc acc_x_hi
!:
*/
    lda #state_ROLLING
    sta state
    jsr collide

safe:
    jsr store_safe_location
    jmp done

collide:
    jsr reset_to_safe
done:
    rts
}

}
