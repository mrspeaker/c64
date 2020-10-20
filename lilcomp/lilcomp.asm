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

        .const state_INIT = 1
        .const state_WALKING = 2
        .const state_WAIT_AIM_FIRE = 3
        .const state_AIMING = 4
        .const state_ROLLING = 5

        .const joy_UP    = %00000001
        .const joy_DOWN  = %00000010
        .const joy_LEFT  = %00000100
        .const joy_RIGHT = %00001000
        .const joy_FIRE  = %00010000

        .const scr_LEFT_HIDDEN_AREA = 24
        .const scr_TOP_HIDDEN_AREA = 50
        .const scr_RIGHT_EDGE_FROM_MSB = 88

        #import "src/player.asm"
        #import "src/cursor.asm"
        #import "src/peeps.asm"
        #import "src/physics.asm"
        #import "src/tiles.asm"
        #import "src/map.asm"
        #import "src/sound.asm"
        #import "src/hud.asm"
        #import "src/utils.asm"

entry:  {
    lda #$0
    sta $d020
    sta $d021

    jsr MAP.copy_chars
    jsr MAP.draw_screen
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
    jsr PEEPS.update
    jsr position_sprites
    jsr TILES.animate
    jsr HUD.update
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
    jsr CURSOR.update
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

    lda #%00011000
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

     // Align cursor (move back/left cursro so center is at x/y)
    lda $d008
    sec
    sbc #4
    sta $d008
    bcs !+
    lda $d010
    eor #%00010000 // msb
    sta $d010
!:

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

        //===================
load_level:{
    //=================
    lda hole
    asl
    tax
//    lda LEVELS.lookup, x
    // TODO: load level yo.

    lda LEVELS.MAP.player.spawn_x_lo
    sta b_x_lo
    lda LEVELS.MAP.player.spawn_x_hi
    sta b_x_hi
    lda LEVELS.MAP.player.spawn_y_lo
    sta b_y_lo
    lda LEVELS.MAP.player.spawn_y_hi
    sta b_y_hi

    jsr PHYSICS.reset

    lda #0
    sta stroke

    lda #state_ROLLING
    sta state

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
    lda shoot_power
    cmp #PHYSICS.MAX_POWER
    bcs !+
    inc shoot_power
    sta $d02b
!:
    jmp shot_done

did_we_shoot:
    lda shoot_power
    beq shot_done

shoot:
    jsr SOUND.sfx
    inc stroke
    inc total_strokes

    jsr PHYSICS.reset

    ldx CURSOR.angle
    ldy shoot_power
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
    jsr CURSOR.hide

    lda #state_ROLLING
    sta state
    lda #0
    sta shoot_power

shot_done:
    rts
}

//======================
stop_rolling:{
//======================

    jsr PHYSICS.reset

    lda #state_WALKING
    sta state

is_in_hole:
    lda cell_cur_attr
    and #%11110000
    cmp #TILES.tile_HOLE
    bne done
    // Hole complete!
    jsr load_level
done:
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
    jsr MAP.get_cell

    sta cell_cur_attr
    stx cell_cur_x
    sty cell_cur_y

    ldx TMP3
    stx cell_cur_value

    tax
    cmp #TILES.tile_SOLID
    beq collide
    txa
    cmp #TILES.tile_LADDER_TOP
    beq ladder
    txa
    cmp #TILES.tile_PICKUP
    beq pickup

    lda cell_cur_value
    cmp #31
    bne safe
vent:
    jsr PHYSICS.apply_jetpack
    jmp safe

pickup:
    jsr get_pickup
safe:
    jsr store_safe_location
    jmp done

ladder:
    // ladder..
collide:
    jsr PHYSICS.reflect_bounce
    jsr reset_to_safe

done:
    rts
}

get_pickup:{
    // in a = cell value
    // x = cell
    //y = ycell
    lda #TILES.tile_EMPTY_ID
    ldx cell_cur_x
    ldy cell_cur_y
    jsr MAP.set_cell
    rts
}

vent:   {
    jsr PHYSICS.apply_jetpack
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


state:  .byte state_ROLLING
hole:   .byte 0
par:    .byte 4
stroke: .byte 0
total_strokes:  .word $0000

input_state:.byte 0

p_x_lo: .byte 0, 0, 0, 0, 0
p_x_hi: .byte $2e, $75, $20, 0, 0
p_y_lo: .byte $00, $00, $00, 0, 0
p_y_hi: .byte $62, $22, $42, 0, 0

p_x_min:.byte $2d, $2d, $11, 0, 0
p_x_max:.byte $47, $7f, $27, 0, 0
p_sp:   .byte 25, 30, -20, 0, 0

cell_cur_attr:     .byte 0
cell_cur_x:         .byte 0
cell_cur_y:.byte 0
cell_cur_value:         .byte 0

last_safe_x_cell:.byte 0
last_safe_y_cell: .byte 0
player_moved:.byte 0
out_of_bounds:.byte 0

shoot_power:.byte $00

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

#import "data/levels_data.asm"
#import "data/charset_data.asm"
#import "data/map_data.asm"
