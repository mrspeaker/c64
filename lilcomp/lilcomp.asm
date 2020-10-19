        BasicUpstart2(entry)

        .const TMP1 = $e8
        .const TMP2 = $e9
        .const TMP3 = $e6
        .const TMP4 = $e7

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

        .const tile_SOLID  = %00010000
        .const tile_HOLE   = %00100000
        .const tile_PICKUP = %00110000
        .const tile_EMPTY_ID = 32

        .const joy_UP    = %00000001
        .const joy_DOWN  = %00000010
        .const joy_LEFT  = %00000100
        .const joy_RIGHT = %00001000
        .const joy_FIRE  = %00010000

        .const scr_LEFT_HIDDEN_AREA = 24
        .const scr_TOP_HIDDEN_AREA = 50
        .const scr_RIGHT_EDGE_FROM_MSB = 88

        #import "player.asm"
        #import "physics.asm"

entry:  {
    lda #$0
    sta $d020
    sta $d021

    jsr copy_chars
    jsr draw_screen
    jsr init_sprites
    jsr init_irq

    jsr load_level

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
    jsr PLAYER.walking
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
    // jsr PHYSICS.apply_move_force
    jsr PHYSICS.check_sleeping

physics:
    jsr PHYSICS.step
    jsr PHYSICS.apply_friction
    jsr check_collisions

!done:
    rts
}

        //======================
update_hud:{
        //======================

    lda cursor_angle+1
    jsr byte_to_decimal
    sty $415
    stx $416
    sta $417

    lda cursor_angle
    jsr byte_to_decimal
    stx $409
    sta $40a

    lda cursor_sp
    jsr byte_to_decimal
sty $420
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
take_a_shot:{
    //======================
    // Check for fire
    lda input_state
    tax

    and #joy_DOWN
    beq go_rolling

    txa
    and #joy_FIRE
    bne did_we_shoot


    // add power.
    lda st_shoot_power
    cmp #PHYSICS.MAX_POWER
    bcs !+
    inc st_shoot_power
    sta $d02b
!:
    jmp shot_done

did_we_shoot:
    lda st_shoot_power
    beq shot_done

shoot:
    inc stroke
    inc total_strokes

    jsr PHYSICS.reset

    ldx cursor_angle
    ldy st_shoot_power
apply:
    lda cos,x
    bpl !pos+
    dec PHYSICS.acc_x_hi
!pos:
    adc PHYSICS.acc_x_lo
    sta PHYSICS.acc_x_lo
    bcc !nover+
    inc PHYSICS.acc_x_hi
!nover:

    lda sin,x
    bpl !pos+
    dec PHYSICS.acc_y_hi
!pos:
    adc PHYSICS.acc_y_lo
    sta PHYSICS.acc_y_lo
    bcc !nover+
    inc PHYSICS.acc_y_hi
!nover:
    dey
    bpl apply

go_rolling:
    jsr hide_cursor

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

//======================
stop_rolling:{
//======================

    jsr PHYSICS.reset

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
    // reset color
    lda #1
    sta $d02b
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
    jsr PHYSICS.reflect_bounce
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
    .label moved_cursor = TMP1

    lda #0
    sta moved_cursor

    lda input_state
    tax
    and #joy_LEFT
    bne right
left:
    inc moved_cursor

    lda cursor_sp
    bmi !+
    lda #0
!:
    clc
    adc #-2
    bmi !+
    lda #$80 // clamp
!:
    sta cursor_sp
    jmp move_cursor

right:
    txa
    and #joy_RIGHT

    bne no_move
    inc moved_cursor

    lda cursor_sp
    bpl !+
    lda #0
!:
    clc
    adc #2
    bpl !+
    lda #$7f // clamp
!:
    sta cursor_sp

move_cursor:
    ldy #5
apply:
    clc
    lda cursor_sp
    bpl !pos+
    dec cursor_angle
!pos:
    adc cursor_angle+1
    sta cursor_angle+1
    bcc !nover+
    inc cursor_angle
!nover:
    dey
    bpl apply

no_move:
    // Reset cursor speeds
    lda moved_cursor
    bne cursor_pos
    lda #0
    sta cursor_sp
    sta cursor_sp+1


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

set_color:
    txa //lda cursor_angle
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

last_safe_x_cell:.byte 0
last_safe_y_cell: .byte 0
player_moved:.byte 0
out_of_bounds:.byte 0

cursor_angle:.byte -256/4, 0
cursor_sp:.byte 0, 0

st_shoot_power:.byte $00
          // Timers
t:      .byte 0
tile_anim_counter: .byte 0

// vel_x_lo:.byte $0
// vel_x_hi:.byte $0
// vel_y_lo:.byte $0
// vel_y_hi:.byte $0

// acc_x_hi:.byte $00
// acc_x_lo:.byte $00
// acc_y_hi:.byte $00
// acc_y_lo:.byte $00

cos:    .fill 256, cos(toRadians(360/256*i))*127
sin:    .fill 256, sin(toRadians(360/256*i))*127

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

#import "./levels.asm"
#import "./charset.asm"
#import "./map.asm"
