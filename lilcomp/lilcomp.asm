        BasicUpstart2(entry)

        //.watch $ef

        .label ADDR_CHAR_MAP_DATA         = $1800 // label = 'map_data'            (size = $03e8).
        .label ADDR_CHARSET_ATTRIB_DATA   = $2700 // label = 'charset_attrib_data' (size = $0100).
        .label ADDR_CHARSET_DATA          = $2800 // label = 'charset_data'        (size = $0800).

        .const MAP_FRAME=1*$3e8
        .const NUM_PEEPS = 3

        // TODO: these don't need to be zero page
        .const SAFE_X_LO = $ea
        .const SAFE_X_HI = $eb
        .const SAFE_Y_LO = $ec
        .const SAFE_Y_HI = $ed
        .const CELL_CUR_X = $ee
        .const CELL_CUR_Y = $ef

        .const b_x_lo = p_x_lo+3
        .const b_x_hi = p_x_hi+3
        .const b_y_lo = p_y_lo+3
        .const b_y_hi = p_y_hi+3
        .const cursor_x_lo = p_x_lo+4
        .const cursor_x_hi = p_x_hi+4
        .const cursor_y_lo = p_y_lo+4
        .const cursor_y_hi = p_y_hi+4

        .const state_INIT = 1
        .const state_WALKING = 2
        .const state_WAIT_AIM_FIRE = 3
        .const state_AIMING = 4
        .const state_ROLLING = 5

        .const phsy_MIN_X_SPEED = 3

        .const tile_SOLID = %00010000

entry:  {
    lda #$0
    sta $d020
    sta $d021

    jsr copy_chars
    jsr draw_screen
    jsr init_sprites
    jsr init_irq
    jmp *
}

        //======================
main: {
        //======================
    jsr get_input
    jsr handle_state
    jsr update_peeps
    jsr position_sprites
    jsr rotate_water
    rts
}

        //======================
handle_state:{
        //======================

    lda state

st_walking:
        cmp #state_WALKING
        bne st_wait_fire
        jsr walking
        jmp !done+

st_wait_fire:
        cmp #state_WAIT_AIM_FIRE
        bne st_aiming
        lda input_state
        and #%00010000
        beq physics
        lda #state_AIMING
        sta state
        jmp physics

st_aiming:
        cmp #state_AIMING
        bne st_rolling
        jsr update_cursor
        jsr take_a_shot
        jmp physics

st_rolling:
        cmp #state_ROLLING
        bne physics
        jsr check_sleeping

physics:
        jsr update_physics
        jsr friction
        jsr collisions

!done:

}

        //======================
init_irq:
        //======================
        sei
        lda #$7f
        sta $dc0d
        lda $dc0d

        lda #1
        sta $d01a

        lda #<irq
        ldx #>irq
        sta $314
        stx $315

        lda #20
        sta $d012
        lda $d011
        and #%01111111
        sta $d011

        cli
        rts

        //======================
irq:
        //======================

//        dec $d020
        dec $d019
        jsr main
//        inc $d020
        pla
        tay
        pla
        tax
        pla
        rti

        //======================
get_input: {
        //======================
        lda $dc00
        sta input_state
        rts
}

        //======================
init_sprites:{
        //======================

        lda #%00011111
        sta $d015
        sta $d01c

        lda #$9
        sta $d025
        lda #$4
        sta $d026
        lda #1
        .for(var i=0;i<NUM_PEEPS+2;i++){
            sta $d027+i
        }
        lda #7
        sta $d02a

        ldx #64*2
!:      lda spr_data,x
        sta $340,x
        dex
        bpl !-

        lda #$340/64
        .for(var i=0;i<NUM_PEEPS+2;i++){
            sta $7f8+i
        }
        lda #$340/64+1
        sta $7fc
        rts
}

        //======================
position_sprites:{
        //======================
        .for(var i=NUM_PEEPS+1;i>=0;i--) {
            lda p_x_lo+i // xpos is 16-bit, 9.7 fixed point (9th bit is MSB sprite X)
            asl     // ... carry has the highest bit of our low byte
            lda p_x_hi+i
            rol     // shifts the Carry flag (bit 8) into place, making A the low 8
                    // bits of the 9-bit pixel coordinate
            sta $d000+(i*2)
            rol $d010

            lda p_y_lo+i
            asl
            lda p_y_hi+i
            rol
            sta $d001+(i*2)
        }
        rts
}

copy_chars:
        // note: was copy, now just point at $2800
        lda $d018
        and #%11110001
        ora #%00001010 // $2800
        sta $d018
        rts

draw_screen:
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

    //======================
walking: {
    //======================
    lda input_state
wup:    lsr
        bcs wdown
        dec b_y_hi
wdown:  lsr
        bcs wleft
        inc b_y_hi
wleft:  lsr
        bcs wright
        dec b_x_hi
wright: lsr
        bcs wfire
        inc b_x_hi
wfire:  lsr
        bcs still_walking
        lda #state_WAIT_AIM_FIRE
        sta state
still_walking:
    rts
}

    //======================
take_a_shot:{
    //======================

        // Check for fire
        lda input_state
        and #%00010000
        bne did_we_shoot

        // add power.
        inc st_shoot_power
        jmp shot_done
did_we_shoot:
        ldy st_shoot_power
        beq shot_done
yep_we_did:
//         // scale down power
//         lda st_shoot_power
//         //asl
//         //asl
//         sta st_shoot_power
//         tay

//         ldx cursor_dir
//        // .break
// apply_acc:
//         lda cos,x
//         bpl !pos+
//         dec acc_x_hi
// !pos:   adc acc_x_lo
//         sta acc_x_lo
//         bcc !nover+
//         inc acc_x_hi
// !nover:

//         lda sin,x
//         bpl !pos+
//         dec acc_y_hi
// !pos:   adc acc_y_lo
//         sta acc_y_lo
//         bcc !nover+
//         inc acc_y_hi
// !nover:

//         dey
                    //         bpl apply_acc
    ldx cursor_dir
    lda cos,x
    bpl !pos+
    dec acc_x_hi
!pos:
    adc acc_x_lo
    sta acc_x_lo
    bcc !nover+
    inc acc_x_hi
!nover:

    lda sin,x
    bpl !pos+
    dec acc_y_hi
!pos:
    adc acc_y_lo
    sta acc_y_lo
    bcc !nover+
    inc acc_y_hi
!nover:

go_rolling:
    lda #state_ROLLING
    sta state
    lda #0
    sta st_shoot_power

shot_done:
        rts
}

        //======================
update_peeps:{
        //======================

        ldx #NUM_PEEPS-1
!:
        // TODO: convert this to signed direction
        lda p_dir,x
        beq sub
        lda p_x_lo,x
        clc
        adc p_sp,x
        sta p_x_lo,x
        lda p_x_hi,x
        adc #0
        sta p_x_hi,x
        cmp p_x_max,x
        bmi !done+
        lda #0
        sta p_dir,x
sub:
        lda p_x_lo,x
        sec
        sbc p_sp,x
        sta p_x_lo,x
        lda p_x_hi,x
        sbc #0
        sta p_x_hi,x
        cmp p_x_min,x
        bpl !done+
        lda #1
        sta p_dir,x
!done:
        dex
        bpl !-
        rts
}

        //======================
update_physics:{
        //======================

        // Add X acc, and clamp velocity
xx:
//         lda vel_x
//         clc
//         adc acc_x_hi //todo: should be both bytes

// !clamp: bvc !nover+
//         bmi !cmax+
// !cmin:  lda #$80
//         jmp !nover+
// !cmax:  lda #$7f

                    // !nover: sta vel_x
    clc
    lda acc_x_lo
    adc vel_x_lo
    sta vel_x_lo
    lda acc_x_hi
    adc vel_x_hi
    sta vel_x_hi

        lda #0 // reset acc
        sta acc_x_lo
        sta acc_x_hi

//         // update X screen pos
//         clc
//         lda vel_x
//         bpl !pos+
//         dec p_x_hi+3
// !pos:   adc p_x_lo+3
//         sta p_x_lo+3
//         bcc !nover+
//         inc p_x_hi+3
                    // !nover:

    clc
    lda vel_x_lo
    adc p_x_lo+3
    sta p_x_lo+3
    lda vel_x_hi
    adc p_x_hi+3
    sta p_x_hi+3

//         // Add Y acc, and clamp velocity
// yy:     lda vel_y
//         clc
//         adc acc_y_hi // todo: should be both bytes
// !clamp: bvc !nover+
//         bmi !cmax+
// !cmin:  lda #$80
//         jmp !nover+
// !cmax:  lda #$7f
                    // !nover: sta vel_y

    clc
    lda acc_y_lo
    adc vel_y_lo
    sta vel_y_lo
    lda acc_y_hi
    adc vel_y_hi
    sta vel_y_hi

        // Apply gravity, reset acc
        lda grav
        sta acc_y_lo
        lda #0
        sta acc_y_hi

//    $f0  11110000
//   +$ff  11111111

//         // update Y screen pos
//         clc
//         lda vel_y
//         bpl !pos+
//         dec p_y_hi+3
// !pos:   adc p_y_lo+3
//         sta p_y_lo+3
//         bcc !nover+
//         inc p_y_hi+3
// !nover:
                    //         rts
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
friction: {
        //======================

fric_y:
    lda bounced_y
    beq fric_y_done
    dec bounced_y

    lda vel_y_hi
    lsr
    ror vel_y_lo
    lda vel_y_hi
    cmp #$80
    ror

fric_y_done:
fric_x:
    lda bounced_x
    beq fric_done
    dec bounced_x

    lda vel_x_hi
    lsr
    ror vel_x_lo
    lda vel_x_hi
    cmp #$80
    ror

fric_done:
    rts
}

        //======================
check_sleeping:{
        //======================

    // is stopped rolling?
    lda vel_y_hi
    bpl !pos+
    lda vel_y_lo
    cmp #$fd
    bmi still_roll
    jmp wait_stop
!pos:
    bne still_roll
    lda vel_y_lo
    cmp #phys_MIN_X_SPEED
    bcs still_roll
    dec $d020
wait_stop:
    //dec $d020
    inc sleep_t
    lda sleep_t
    cmp #20
    bne !done+

    lda #0
    sta vel_x_lo
    sta vel_x_hi
    sta vel_y_lo
    sta vel_y_hi

    lda #state_WALKING
    sta state
still_roll:
    lda #0
    sta sleep_t
!done:
    rts
}

        //======================
rotate_water: {
        //======================
        lda wav_lo
        clc
        adc #40
        sta wav_lo
        bcc !+

        ldy ADDR_CHARSET_DATA+(87*8)+7
        ldx #7
rot:
        lda ADDR_CHARSET_DATA+(87*8),x
        sta ADDR_CHARSET_DATA+(87*8)+1,x
        dex
        bpl rot
        sty ADDR_CHARSET_DATA+(87*8)
!:
        rts
}

        //======================
collisions: {
        //======================

    // Convert pos to X/Y cell locations
        clc
        ldy #0
        lda b_x_lo
        asl
        lda b_x_hi
        rol
        bcc !+
        cmp #80 // right edge of screen (why 80?)
        bcc !e+
        rts
!e:
        cmp #24 // left hidden area
        bcc !+
        ldy #1 // MSB is set
!:
        sec
        sbc #24 // left hidden area
        lsr
        lsr
        lsr
        cpy #1 // MSB was set?
        bne !+
        adc #31 // MSB was set: add more tiles
!:
        tax
        sta CELL_CUR_X

        // Y
        clc
        lda b_y_lo
        asl
        lda b_y_hi
        rol
        sec
        sbc #45
        lsr
        lsr
        lsr
        tay
        sta CELL_CUR_Y

        lda SCREEN_ROW_LSB,y
        sta $10
        lda SCREEN_ROW_MSB,y
        sta $11
        txa
        tay

        // Check tile attrib
        lda ($10),y
        tax
        lda charset_attrib_data,x
        and #tile_SOLID
        beq safe

collide:
        lda SAFE_X_LO
        sta b_x_lo
        lda SAFE_X_HI
        sta b_x_hi
        lda SAFE_Y_LO
        sta b_y_lo
        lda SAFE_Y_HI
        sta b_y_hi
/*
   todo: check collision y, x...
 */

reflect:
        lda CELL_CUR_X
        sec
        sbc last_safe_x_cell

        // == is hit from top/bottom
        beq refl_y

        // >0 is hit from left
        // <0 is hit from right
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
        // $ef - safe_y
        lda CELL_CUR_Y
        sec
        sbc last_safe_y_cell

        // == is hit from left/right
        beq !done+
        // >0 is hit from bottom
        // <0 is hit from top
        clc
        lda vel_y_lo
        eor #$ff
    adc #1
    sta vel_y_lo
    lda vel_y_hi
    eor #$ff
    sta vel_y_hi

        lda #1
        sta bounced_y

        jmp !done+

safe:
        // store safe location
        lda b_x_lo
        sta SAFE_X_LO
        lda b_x_hi
        sta SAFE_X_HI
        lda b_y_lo
        sta SAFE_Y_LO
        lda b_y_hi
        sta SAFE_Y_HI

        lda CELL_CUR_X
        sta last_safe_x_cell
        lda CELL_CUR_Y
        sta last_safe_y_cell

!done:

    rts
}

        //======================
update_cursor:{
        //======================

    lda input_state
    tax
    and #%00000100
    bne no_left
    dec cursor_dir
no_left:
    txa
    and #%00001000
    bne no_right
    inc cursor_dir
no_right:

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

    ldx cursor_dir

    ldy #15
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
    dey
    bpl mulx

    ldy #15
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
    bpl muly

    rts
}


state:  .byte state_WALKING
state_t:.byte 0
input_state:.byte 0

p_dir:  .byte 1,1,0,0,0
p_x_lo: .byte 0,0,0,%10000000,0
p_x_hi: .byte $2e, $75, $20, $10, $0
p_y_lo: .byte $00, $00, $00, $00, $0
p_y_hi: .byte $62, $22, $42, $42, $0

p_x_min:.byte $2c, $29, $d, 0, 0
p_x_max:.byte $48, $7d, $21, 0, 0
p_sp:   .byte 25,30,20, 0, 0

grav:   .byte $2
vel_x_lo:.byte $0
vel_x_hi:.byte $0
vel_y_lo:.byte $0
vel_y_hi:.byte $0

acc_x_lo:.byte $00
acc_x_hi:.byte $00
acc_y_lo:.byte $00
acc_y_hi:.byte $00

cursor_dir:.byte $0
st_shoot_power:.byte $00
bounced_x:.byte $0
bounced_y:.byte $0
sleep_t:            .byte $0
wav_lo: .byte 0
wav_hi: .byte 0

last_safe_x_cell: .byte 0
last_safe_y_cell: .byte 0

t:      .byte 0

spr_data:
        .byte %11000000,%00000000,%00000000
        .byte %10000000,%00000000,%00000000
        .byte %10000000,%00000000,%00000000
        .byte %10000000,%00000000,%00000000
        .byte %10000000,%00000000,%00000000
        .byte %11000000,%00000000,%00000000
        .fill 15*3, 0
        .byte 0

        .byte %00110000,%00000000,%00000000
        .byte %11001100,%00000000,%00000000
        .byte %00110000,%00000000,%00000000
        .fill 18*3, 0
        .byte 0

lol:    .fill 4,$aa
sin:    .fill 256, sin(toRadians(360/256*i))*128
lol2:    .fill 4, $55
cos:    .fill 256, cos(toRadians(360/256*i))*128
lol3:   .fill 4,$aa

SCREEN_ROW_LSB:
        .fill 25, <[$0400 + i * 40]
SCREEN_ROW_MSB:
        .fill 25, >[$0400 + i * 40]

#import "./charset.asm"
#import "./map.asm"
