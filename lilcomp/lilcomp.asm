        BasicUpstart2(entry)

        .label ADDR_CHAR_MAP_DATA         = $1800 // label = 'map_data'            (size = $03e8).
        .label ADDR_CHARSET_ATTRIB_DATA   = $2700 // label = 'charset_attrib_data' (size = $0100).
        .label ADDR_CHARSET_DATA          = $2800 // label = 'charset_data'        (size = $0800).

        .const MAP_FRAME = 0*$3e8
        .const NUM_PEEPS = 3

        // TODO: these don't need to be zero page
        .const SAFE_X_LO = $ea
        .const SAFE_X_HI = $eb
        .const SAFE_Y_LO = $ec
        .const SAFE_Y_HI = $ed

        .const TMP1 = $e8
        .const TMP2 = $e9
        .const TMP3 = $e6
        .const TMP4 = $e7


        .const b_x_lo = p_x_lo+3
        .const b_x_hi = p_x_hi+3
        .const b_y_lo = p_y_lo+3
        .const b_y_hi = p_y_hi+3
        .const cursor_x_lo = p_x_lo+4
        .const cursor_x_hi = p_x_hi+4
        .const cursor_y_lo = p_y_lo+4
        .const cursor_y_hi = p_y_hi+4
        .const cursor_DISTANCE = 10

        .const state_INIT = 1
        .const state_WALKING = 2
        .const state_WAIT_AIM_FIRE = 3
        .const state_AIMING = 4
        .const state_ROLLING = 5

        .const phys_MIN_SPEED_FOR_SLEEP = 5
        .const phys_SLEEP_FRAMES = 10
        .const phys_GRAVITY = 200
        .const phys_AIR_MOVE_SPEED = 40
        .const phys_MAX_POWER = 65

        .const phys_WALK_SPEED = 80

        .const tile_SOLID  = %00010000
        .const tile_HOLE   = %00100000
        .const tile_PICKUP = %00110000
        .const tile_EMPTY_ID = 32

        .const scr_LEFT_HIDDEN_AREA = 24
        .const scr_TOP_HIDDEN_AREA = 50
        .const scr_RIGHT_EDGE_FROM_MSB = 88

entry:  {
    lda #$0
    sta $d020
    sta $d021

    jsr copy_chars
    jsr draw_screen
    jsr init_sprites
    jsr init_irq

//    jsr load_level

    jmp *
}

        //======================
main: {
        //======================
    jsr get_input
    jsr handle_state
    jsr update_peeps
    jsr position_sprites
    jsr anim_tiles
    jsr update_hud
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
    jsr apply_move_force
    jsr check_sleeping

physics:
    jsr step_physics
    jsr apply_friction
    jsr check_collisions

!done:

    rts

}

        //======================
update_hud:{
        //======================

    lda st_shoot_power
    jsr byte_to_decimal
    stx $416
    sta $417

    lda stroke
    jsr byte_to_decimal
    stx $409
    sta $40a

    lda hole
    jsr byte_to_decimal
    stx $421
    sta $422
    rts
}

byte_to_decimal:{
    //in: a = value
    //out: a=1s, x=10s, y=100s
    ldy #$2f
    ldx #$3a
    sec
!:  iny
    sbc #100
    bcs !-
!:  dex
    adc #10
    bmi !-
    adc #$2f
    rts
}

        //======================
init_irq:{
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

    lda #$ff
    sta $d012
    lda $d011
    and #%01111111
    sta $d011

    cli
    rts
}
        //======================
irq:    {
    //======================

    dec $d019
//    inc $d020
    jsr main
//    dec $d020
    pla
    tay
    pla
    tax
    pla
    rti
}

        //======================
get_input: {
    //=========================
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
!:  lda spr_data,x
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
        asl         // ... carry has the highest bit of our low byte
        lda p_x_hi+i
        rol         // shifts the Carry flag (bit 8) into place, making A the low 8
                    // bits of the 9-bit pixel coordinate
        sta $d000+(i*2)
        rol $d010

        lda p_y_lo+i
        asl
        lda p_y_hi+i
        rol
        sta $d001+(i*2)
    }
    // Align cursor
    // TODO: account for MSB carry!
    dec $d008
    dec $d008
    dec $d008
    dec $d008
    dec $d009
    dec $d009

    /* move up player (and cursr)
       TODO: better way to position/collision playre.
       currently everything is based off top-left pixel.
     */


    dec $d009
    dec $d009
    dec $d009

    dec $d007
    dec $d007
    dec $d007
    dec $d007
    dec $d007
    rts
}

copy_chars:{
    // note: was copy, now just point at $2800
    lda $d018
    and #%11110001
    ora #%00001010  // $2800
    sta $d018
    rts
}

        //===================
load_level:{
    //=================
    lda hole
    asl
    tax
//    lda LEVELS.lookup, x
    // TODO: load level yo.
    rts
}

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
    lda #-phys_WALK_SPEED
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
    lda #phys_WALK_SPEED
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

    //======================
take_a_shot:{
    //======================
    // Check for fire
    lda input_state
    and #%00010000
    bne did_we_shoot

    // add power.
    lda st_shoot_power
    cmp #phys_MAX_POWER
    bcs !+
    inc st_shoot_power
    sta $d02b
!:
    jmp shot_done

did_we_shoot:
    ldy st_shoot_power
    beq shot_done

shoot:
    jsr hide_cursor
    inc stroke
    inc total_strokes

    // reset color
    lda #1
    sta $d02b
    jsr reset_physics

    ldx cursor_angle
    ldy st_shoot_power
apply:
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
    dey
    bpl apply

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
    lda p_sp,x
    bpl !pos+
    dec p_x_hi,x
!pos:
    adc p_x_lo,x
    sta p_x_lo,x
    bcc !nover+
    inc p_x_hi,x
!nover:
    lda p_x_hi,x
    cmp p_x_min,x
    bmi flip
    lda p_x_hi,x
    cmp p_x_max,x
    bpl flip
    jmp !done+
flip:
    clc
    lda p_sp,x
    eor #$ff
    adc #1
    sta p_sp,x
!done:
    dex
    bpl !-
    rts
}

reset_physics:{
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
step_physics:{
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
    lda #phys_GRAVITY
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

apply_move_force:{
    // TODO: how to move....
    // maybe try only move horiz if bounce_y and vel_y is small?
    rts
    //
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
    sbc #phys_AIR_MOVE_SPEED
    sta acc_x_lo
    bcs !+
    dec acc_x_hi

    jmp done
right:
    clc
    lda acc_x_lo
    adc #phys_AIR_MOVE_SPEED
    sta acc_x_lo
    bcc !+
    inc acc_x_hi
!:
done:
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
    cmp #phys_MIN_SPEED_FOR_SLEEP
    bcs !done+
    jmp wait_stop

!pos:
    // going downwards
    bne still_roll
    lda vel_y_lo
    cmp #phys_MIN_SPEED_FOR_SLEEP
    bcs !done+
wait_stop:
    inc sleep_t
    lda sleep_t
    cmp #phys_SLEEP_FRAMES
    bne !done+
    jsr stop_rolling
still_roll:
    lda #0
    sta sleep_t
!done:
    rts
}

stop_rolling:{
    jsr reset_physics

    lda #state_WALKING
    sta state

is_in_hole:
    lda cell_cur_value
    and #%11110000
    cmp #tile_HOLE
    bne done
    // Hole complete!
    dec $d020
done:
    rts
}

hide_cursor:{
    lda #0
    sta cursor_x_hi
    sta cursor_y_hi
    rts
}

        //======================
anim_tiles: {
        //======================
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

        //======================
check_collisions: {
    //======================

    lda b_x_lo
    sta TMP1
    lda b_x_hi
    sta TMP2
    lda b_y_lo
    sta TMP3
    lda b_y_hi
    sta TMP4
    jsr get_cell

    sta cell_cur_value
    stx cell_cur_x
    sty cell_cur_y

    and #%11110000
    tax
    cmp #tile_SOLID
    beq collide
    txa
    cmp #tile_PICKUP
    bne safe
    jsr get_pickup
safe:
    jsr store_safe_location
    jmp !done+

collide:
    jsr reflect_bounce
    jsr reset_to_safe

!done:
    rts
}

get_pickup:{
                    // in a = cell value
                    // x = cell
                    //y = ycell
    lda #tile_EMPTY_ID
    ldx cell_cur_x
    ldy cell_cur_y
    jsr set_cell
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

get_cell:            {
    //in: tmp0-4 x_lo,x_hi,y_lo,y_hi
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
    lda #tile_SOLID
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
    tax
    lda charset_attrib_data,x
load:
    ldx TMP1 // X_CELL
    ldy TMP2 // Y_CELL
done:
    rts
}


reflect_bounce:{
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
 */
    lda #0
    sta TMP1

refl_x:
    lda cell_cur_x
    sec
    sbc last_safe_x_cell

    // == is same cell: must have hit from top/bottom
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

    inc TMP1

refl_y:
    lda cell_cur_y
    sec
    sbc last_safe_y_cell

    // == is same cell, must have hit from left/right
    beq done

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
    // We bounced Y
    lda #1
    sta bounced_y
    inc TMP1

done:
    lda TMP1
    cmp #2
    bne !+
both_axis_hit:
//    dec $d021
    ldx vel_x_hi
    ldy vel_y_hi
    // TODO: bug here - bounces of X & Y when should only
    // bounce off one depending on... velocity?
//    .break
//    bit $ea
!:
    rts
}


store_safe_location:{
    lda b_x_lo
    sta SAFE_X_LO
    lda b_x_hi
    sta SAFE_X_HI
    lda b_y_lo
    sta SAFE_Y_LO
    lda b_y_hi
    sta SAFE_Y_HI

    lda cell_cur_x
    sta last_safe_x_cell
    lda cell_cur_y
    sta last_safe_y_cell
    rts
}

reset_to_safe:{
    lda SAFE_X_LO
    sta b_x_lo
    lda SAFE_X_HI
    sta b_x_hi
    lda SAFE_Y_LO
    sta b_y_lo
    lda SAFE_Y_HI
    sta b_y_hi
    rts
}

        //======================
update_cursor:{
        //======================

    lda input_state
    tax
    and #%00000100
    bne no_left
    // todo: accelerate cursor angle.
    dec cursor_angle
no_left:
    txa
    and #%00001000
    bne no_right
    inc cursor_angle
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

move_angle:
    ldx cursor_angle
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

    rts
}


state:  .byte state_ROLLING
hole:   .byte 0
par:    .byte 4
stroke: .byte 0
total_strokes:  .word $0000

input_state:.byte 0

p_x_lo: .byte 0, 0, 0, 0, 0
p_x_hi: .byte $2e, $75, $20, $60, $0
p_y_lo: .byte $00, $00, $00, $00, $0
p_y_hi: .byte $62, $22, $42, $42, $0

p_x_min:.byte $2d, $2d, $11, 0, 0
p_x_max:.byte $47, $7f, $27, 0, 0
p_sp:   .byte 25, 30, -20, 0, 0

cell_cur_value:     .byte 0
cell_cur_x:         .byte 0
cell_cur_y:         .byte 0


vel_x_lo:.byte $0
vel_x_hi:.byte $0
vel_y_lo:.byte $0
vel_y_hi:.byte $0

last_safe_x_cell:.byte 0
last_safe_y_cell: .byte 0
player_moved:.byte 0
out_of_bounds:.byte 0

cursor_angle:.byte -256/4
st_shoot_power:.byte $00
bounced_x:.byte $0
bounced_y:.byte $0
          // Timers
t:      .byte 0
sleep_t:.byte $0
tile_anim_counter: .byte 0

cos:    .fill 256, cos(toRadians(360/256*i))*127
sin:    .fill 256, sin(toRadians(360/256*i))*127

acc_x_hi:.byte $00
acc_x_lo:.byte $00
acc_y_hi:.byte $00
acc_y_lo:.byte $00

spr_data:
        .byte %11000000,%00000000,%00000000
        .byte %10000000,%00000000,%00000000
        .byte %10000000,%00000000,%00000000
        .byte %10000000,%00000000,%00000000
        .byte %10000000,%00000000,%00000000
        .byte %11000000,%00000000,%00000000
        .fill 15*3, 0
        .byte 0

        .byte $15,$00,$00,$59,$40,$00,$62,$40
        .byte $00,$59,$40,$00,$15,$00,$00,$00
        .fill 8*6, 0

SCREEN_ROW_LSB:
        .fill 25, <[$0400 + i * 40]
SCREEN_ROW_MSB:
        .fill 25, >[$0400 + i * 40]

//# import "./levels.asm"
#import "./charset.asm"
#import "./map.asm"
