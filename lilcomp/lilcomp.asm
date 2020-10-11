        BasicUpstart2(entry)

        .label ADDR_CHAR_MAP_DATA         = $1800 // label = 'map_data'            (size = $03e8).
        .label ADDR_CHAR_MAP_COLOUR_DATA  = $1be8 // label = 'map_colour_data'     (size = $03e8).
        .label ADDR_CHARSET_DATA          = $2800 // label = 'charset_data'        (size = $0800).

        .const PHYS_REPS = 2
        .const NUM_PEEPS = 3

        .const b_x_lo = p_x_lo+3
        .const b_x_hi = p_x_hi+3
        .const b_y_lo = p_y_lo+3
        .const b_y_hi = p_y_hi+3
        .const cursor_x_lo = p_x_lo+4
        .const cursor_x_hi = p_x_hi+4
        .const cursor_y_lo = p_y_lo+4
        .const cursor_y_hi = p_y_hi+4

entry:
        lda #$0
        sta $d020
        sta $d021

        jsr copy_chars
        jsr draw_screen
        jsr init_sprites
        jsr init_irq
        jmp *

main:
        jsr get_input
        jsr update_peeps

        lda state
        cmp #2
        bne !done2+

        lda power
        beq !+
        jsr take_a_shot
        dec power
!:
        clc
        dec state_t
        bne !done2+
        lda #1
        sta state
!done2:
        jsr update_phys
        jsr collisions
        jsr update_cursor
        jsr position_sprites
        jsr rotate_water
        rts

init_irq:
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

irq:
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

init_sprites:
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
!:      lda sprite_0,x
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


copy_chars:
        lda $d018
        and #%11110001
        ora #%00001010 // $2800
        sta $d018

draw_screen:
        ldx #0
!:
        .for (var i=0; i<4;i++) {
            lda map_data+(i * $FF), x
            sta $400+(i*$FF),x
            lda map_colour_data+(i * $FF),x
            sta $D800+(i * $FF),x
        }
        inx
        bne !-
        rts


get_input:
        lda $dc00
up:     lsr
        bcs down
down:   lsr
        bcs left
left:   lsr
        bcs right
        dec cursor_dir
right:  lsr
        bcs fire
        inc cursor_dir
fire:   lsr
        bcs !done+
        lda state
        cmp #1
        bne !done+
        lda #2
        sta state
        lda #$20
        sta state_t
        lda #2
        sta power
!done:  rts

update_peeps:
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

update_phys:

xx:
        lda vel_x
        clc
        adc acc_x
        sta vel_x
        lda #0
        sta acc_x

        ldx PHYS_REPS
!:
        clc
        lda vel_x
        bpl !pos+
        dec p_x_hi+3
!pos:   adc p_x_lo+3
        sta p_x_lo+3
        bcc !nover+
        inc p_x_hi+3
!nover:
        dex
        bpl !-

yy:
        lda vel_y
        clc
        adc acc_y
        sta vel_y
        lda #0
        sta acc_y

        ldx PHYS_REPS
!:

        clc
        lda vel_y
        bpl !pos+
        dec p_y_hi+3
!pos:   adc p_y_lo+3
        sta p_y_lo+3
        bcc !nover+
        inc p_y_hi+3
!nover:
        dex
        bpl !-

!done:
        rts

update_cursor:
        lda b_x_lo
        sta cursor_x_lo
        lda b_x_hi
        sta cursor_x_hi
        and #%01111111
        lda b_y_lo
        sta cursor_y_lo
        lda b_y_hi
        and #%01111111

        sta cursor_y_hi

        ldx cursor_dir
        lda cursor_x_hi
        clc
        adc cos,x
        sta cursor_x_hi

        lda cursor_y_hi
        clc
        adc sin,x
        sta cursor_y_hi

        rts

position_sprites:
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

rotate_water:
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

take_a_shot:
        ldx cursor_dir
        lda cos,x
        sta acc_x
        lda sin,x
        sta acc_y

        rts

collisions:
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

        lda SCREEN_ROW_LSB,y
        sta $10
        lda SCREEN_ROW_MSB,y
        sta $11
        txa
        tay
        lda #$5a
        sta ($10),y

        rts

state:  .byte 1
state_t:.byte 0

p_dir:  .byte 1,1,0,1
p_x_lo: .byte 0,0,0,%10000000,0
p_x_hi: .byte $2e, $75, $20, $10, $0
p_y_lo: .byte $00, $00, $00, $00, $0
p_y_hi: .byte $62, $22, $42, $42, $0

p_x_min:.byte $2c, $29, $d
p_x_max:.byte $48, $7d, $21

p_sp:   .byte 25,30,20

grav:   .byte $1
vel_x:  .byte $0
vel_y:  .byte $0

acc_x:  .byte $00
acc_y:  .byte $00
power:  .byte $00

cursor_dir:         .byte $0

wav_lo: .byte 0
wav_hi: .byte 0

sprite_0:
.byte %11000000,%00000000,%00000000
.byte %10000000,%00000000,%00000000
.byte %10000000,%00000000,%00000000
.byte %10000000,%00000000,%00000000
.byte %10000000,%00000000,%00000000
.byte %11000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
        .byte 0

.byte %00110000,%00000000,%00000000
.byte %11001100,%00000000,%00000000
.byte %00110000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%0000000
        .byte 0

sin:    .fill 256, sin(toRadians(360/256*i))*20
cos:    .fill 256, cos(toRadians(360/256*i))*20

SCREEN_ROW_LSB:
        .fill 25, <[$0400 + i * 40]
SCREEN_ROW_MSB:
        .fill 25, >[$0400 + i * 40]

#import "./charset.asm"
#import "./map.asm"
