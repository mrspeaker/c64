PLAYER: {

    .const WALK_SPEED = 80

x_lo:.byte $0
x_hi:.byte $0
y_lo:.byte $0
y_hi:.byte $0

on_ladder:.byte $0


      //======================
walking: {
    //======================
    lda #0
    sta player_moved
    lda input_state
wup:lsr
    bcs wdown
    tax
    // on top of ladder?
    // on ladder?
    // in the "middle" of ladder (check low bytes)
    // walk downwards.
    lda on_ladder
    cmp #1
    bne !+
    lda #-WALK_SPEED
    bpl !pos+
    dec b_y_hi
!pos:
    adc b_y_lo
    sta b_y_lo
    bcc !nover+
    inc b_y_hi
!nover:
!:  txa
wdown:  lsr
    bcs wleft
    tax
// on top of ladder?
    // on ladder?
    // in the "middle" of ladder (check low bytes)
    // walk downwards.
    lda on_ladder
    cmp #1
    bne !+
    lda #WALK_SPEED
    bpl !pos+
    dec b_y_hi
!pos:
    adc b_y_lo
    sta b_y_lo
    bcc !nover+
    inc b_y_hi
!nover:

!:  txa
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
    lda #0
    sta on_ladder

    // Check cell left/right
    lda b_x_lo
    sta TMP1
    lda b_x_hi
    sta TMP2
    lda b_y_lo
    sta TMP3
    lda b_y_hi
    sta TMP4
    jsr MAP.get_cell
    tax
    cmp #TILES.tile_SOLID
    beq collide
    txa
    cmp #TILES.tile_LADDER_TOP
    beq collide
feet:
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
    jsr MAP.get_cell
    tax
    cmp #TILES.tile_SOLID
    beq safe
    txa
    cmp #TILES.tile_LADDER_TOP
    bne !+
    lda #1
    sta on_ladder
    jmp safe
!:

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

//    lda #state_ROLLING
//    sta state
//    jsr PHYSICS.reset
    jmp collide

safe:
    jsr store_safe_location
    jmp done

collide:
    jsr reset_to_safe
done:
    rts
}

}
