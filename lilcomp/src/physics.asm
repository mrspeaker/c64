PHYSICS:  {
    .label MIN_SPEED_FOR_SLEEP = 5
    .label SLEEP_FRAMES = 10
    .label GRAVITY = 200
    .label AIR_MOVE_SPEED = 40
    .label MAX_POWER = 65

    vel_x_lo:.byte $0
    vel_x_hi:.byte $0
    vel_y_lo:.byte $0
    vel_y_hi:.byte $0

    acc_x_hi:.byte $00
    acc_x_lo:.byte $00
    acc_y_hi:.byte $00
    acc_y_lo:.byte $00

bounced_x:.byte $0
bounced_y:.byte $0
sleep_t:.byte $0


//======================
reset: {
//======================
    lda #0
    sta acc_x_hi
    sta acc_x_lo
    sta acc_y_hi
    sta acc_y_lo
    sta vel_y_hi
    sta vel_y_lo
    sta vel_x_hi
    sta vel_x_lo
    sta bounced_x
    sta bounced_y
    rts
}

//======================
step:{
//======================

        // Add X acc, and clamp velocity
xx:
    lda acc_x_lo
    sta TMP1
    lda acc_x_hi
    sta TMP2

    /*
       Scale acceleration down... this is so we have a more
       useful "range" of power in a shot.

       It would be much faster to do this scaling at the time
       that the force was applied - but there would be more
       accumulated error when more forces are combined.
       However, we only have 2: the shot, and gravity.
       So, TODO: look at the numbers and see if scaling down the
       shot in `take_a_shot` is the same as adding forces and
       scaling here.
     */
    .for(var i=0;i<4;i++){
        lda TMP2
        cmp #$80    //copy sign to c
        ror TMP2
        ror TMP1
    }

    clc
    lda TMP1
    adc vel_x_lo
    sta vel_x_lo
    lda TMP2
    adc vel_x_hi
    sta vel_x_hi

    lda #0          // reset acc
    sta acc_x_lo
    sta acc_x_hi

    // update X screen pos
    clc
    lda vel_x_lo
    adc p_x_lo+3
    sta p_x_lo+3
    lda vel_x_hi
    adc p_x_hi+3
    sta p_x_hi+3

    // Add Y acc, and clamp velocity
yy:
    lda acc_y_lo
    sta TMP1
    lda acc_y_hi
    sta TMP2

    // divide acceleartion down
    .for(var i=0;i<4;i++){
        lda TMP2
        cmp #$80    //copy sign to c
        ror TMP2
        ror TMP1
    }

    clc
    lda TMP1
    adc vel_y_lo
    sta vel_y_lo
    lda TMP2
    adc vel_y_hi
    sta vel_y_hi


    // Apply gravity, reset acc
    lda #GRAVITY
    sta acc_y_lo
    lda #0
    sta acc_y_hi

    // update Y screen pos
    clc
    lda vel_y_lo
    adc p_y_lo+3
    sta p_y_lo+3
    lda vel_y_hi
    adc p_y_hi+3
    sta p_y_hi+3

    rts
}

        //======================
apply_friction: {
        //======================

fric_y:
    lda bounced_y
    beq fric_y_done
    dec bounced_y

    lda vel_y_hi
    cmp #$80        //copy sign to c
    ror vel_y_hi
    ror vel_y_lo

    // testing: decrease x on every y hit
    lda vel_x_hi
    cmp #$80
    ror vel_x_hi
    ror vel_x_lo

fric_y_done:
fric_x:
    lda bounced_x
    beq fric_done
    dec bounced_x

    lda vel_x_hi
    cmp #$80
    ror vel_x_hi
    ror vel_x_lo

fric_done:
    rts
}


//======================
apply_move_force: {
//======================

    // TODO: how to move....
    // maybe try only move horiz if bounce_y and vel_y is small?
    // (NOT USED?)
    lda input_state
    and #%00000100
    beq left
    lda input_state
    and #%00001000
    beq right
    jmp done
left:
    sec
    lda acc_x_lo
    sbc #AIR_MOVE_SPEED
    sta acc_x_lo
    bcs !+
    dec acc_x_hi
!:
    jmp done
right:
    clc
    lda acc_x_lo
    adc #AIR_MOVE_SPEED
    sta acc_x_lo
    bcc !+
    inc acc_x_hi
!:
done:
    rts
}

apply_jetpack:{
    ldy #5
lp:
    sec
    lda acc_y_lo
    sbc #$7f
    sta acc_y_lo
    bcs !+
    dec acc_y_hi
!:
    dey
    bpl lp
    rts
}


//======================
check_sleeping:{
//======================

    // is stopped bouncing?
    lda vel_y_hi
    bpl !pos+
    // Going upwards
    clc
    eor #$ff
    bne still_roll
    lda vel_y_lo
    clc
    eor #$ff
    adc #1
    cmp #PHYSICS.MIN_SPEED_FOR_SLEEP
    bcs !done+
    jmp wait_stop

!pos:
    // going downwards
    bne still_roll
    lda vel_y_lo
    cmp #PHYSICS.MIN_SPEED_FOR_SLEEP
    bcs !done+
wait_stop:
    inc sleep_t
    lda sleep_t
    cmp #PHYSICS.SLEEP_FRAMES
    bne !done+
    jsr stop_rolling
still_roll:
    lda #0
    sta sleep_t
!done:
    rts
}

//======================
reflect_bounce:{
//======================

/*
   todo: check collision y, x...
 */

/*
   Have hit something. Need to determine how to bounce.

   We know the last "safe" cell we were in.
   We know the current cell we are in (that is solid).

   If both not new: bad state? stuck?
   If new X and not new Y - reflect off X
   If new Y and not new X - reflect off Y
   If both new... hit a corner.... which reflect?


maybe..

y:
   x-newX > 0 ? [x-1,y] free? no reflect : reflect.
   x-newX < 0 ? [x+1,y] free? no reflect : reflect
x:
  ...
 */
    .const hit_count = TMP5
    .const x_dist = TMP6
    .const y_dist = TMP7
    .const BOTH_AXES_NEW = 2

            lda #0
            sta hit_count

            lda cell_cur_x
            sec
            sbc last_safe_x_cell
            sta x_dist
            beq !+
            inc hit_count
!:
            lda cell_cur_y
            sec
            sbc last_safe_y_cell
            sta y_dist
            beq !+
            inc hit_count
!:


refl_x:
            lda x_dist
    // same X cell: hit from top/bottom
            beq refl_y

    //if hit_count==2, need to check above/below cell.
            ldx hit_count
            cpx #BOTH_AXES_NEW
            bne !+
    // Do we need to reflect on X?
            ldx cell_cur_x
            ldy last_safe_y_cell
            jsr MAP.get_cell_i
            cmp #TILES.tile_SOLID
            bne refl_y

!:
            clc
            lda vel_x_lo
            eor #$ff
            adc #1
            sta vel_x_lo
            lda vel_x_hi
            eor #$ff
            adc #0
            sta vel_x_hi

            lda #1
            sta bounced_x

refl_y:
            lda y_dist

    // == is same cell, must have hit from left/right
            beq done
            ldx hit_count
            cpx #BOTH_AXES_NEW
            bne !+
            // TODO: check same as X: do we need to reflect?
!:
            clc
            lda vel_y_lo
            eor #$ff
            adc #1
            sta vel_y_lo
            lda vel_y_hi
            eor #$ff
            sta vel_y_hi
    // We bounced Y
            lda #1
            sta bounced_y

done:
            rts
}

}
