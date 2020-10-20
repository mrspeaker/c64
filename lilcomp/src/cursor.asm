CURSOR: {

angle:.byte -256/4, 0
speed:.byte 0, 0



hide:{
    lda #0
    sta cursor_x_hi
    sta cursor_y_hi
    // reset color
    lda #1
    sta $d02b
    rts
}

        //======================
update:{
        //======================
    .label moved_cursor = TMP1

    lda #0
    sta moved_cursor

    lda input_state
    tax
    and #joy_LEFT
    bne right
left:
    inc moved_cursor

    lda speed
    bmi !+
    lda #0
!:
    clc
    adc #-2
    bmi !+
    lda #$80 // clamp
!:
    sta speed
    jmp move_cursor

right:
    txa
    and #joy_RIGHT

    bne no_move
    inc moved_cursor

    lda speed
    bpl !+
    lda #0
!:
    clc
    adc #2
    bpl !+
    lda #$7f // clamp
!:
    sta speed

move_cursor:
    ldy #5
apply:
    clc
    lda speed
    bpl !pos+
    dec angle
!pos:
    adc angle+1
    sta angle+1
    bcc !nover+
    inc angle
!nover:
    dey
    bpl apply

no_move:
    // Reset cursor speeds
    lda moved_cursor
    bne reset_power
    lda #0
    sta speed
    sta speed+1
    jmp cursor_pos

reset_power:
    lda #0
    sta st_shoot_power


cursor_pos:
    lda b_x_lo
    sta cursor_x_lo
    lda b_x_hi
    sta cursor_x_hi

    lda b_y_lo
    sta cursor_y_lo
    lda b_y_hi
    and #%01111111
    sta cursor_y_hi

move_angle:
    ldx angle
    ldy #cursor_DISTANCE
mulx:
    clc
    lda cos,x
    bpl !pos+
    dec cursor_x_hi
!pos:
    adc cursor_x_lo
    sta cursor_x_lo
    bcc !nover+
    inc cursor_x_hi
!nover:

muly:
    clc
    lda sin,x
    bpl !pos+
    dec cursor_y_hi
!pos:
    adc cursor_y_lo
    sta cursor_y_lo
    bcc !nover+
    inc cursor_y_hi
!nover:
    dey
    bpl mulx

set_color:
    txa //lda angle
    and #%00011111
    bne !+
    // 45 degree angle.
    lda #5
    jmp done
!:
    lda #1
done:
    sta $d02b
    rts
}


}
