        BasicUpstart2(entry)

        .label ADDR_CHAR_MAP_DATA         = $1800 // label = 'map_data'            (size = $03e8).
        .label ADDR_CHAR_MAP_COLOUR_DATA  = $1be8 // label = 'map_colour_data'     (size = $03e8).
        .label ADDR_CHARSET_DATA          = $2800 // label = 'charset_data'        (size = $0800).

        .const NUM_PEEPS = 3

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
        jsr update_peeps
        jsr update_phys
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
        dec $d020
        dec $d019
        jsr main
        inc $d020
        pla
        tay
        pla
        tax
        pla
        rti

init_sprites:
        lda #%00001111
        sta $d015
        sta $d01c

        lda #$9
        sta $d025
        lda #$4
        sta $d026
        lda #1
        .for(var i=0;i<NUM_PEEPS+1;i++){
            sta $d027+i
        }
        lda #7
        sta $d02a

        ldx #64
!:      lda sprite_0,x
        sta $340,x
        dex
        bpl !-

        lda #$340/64
        .for(var i=0;i<NUM_PEEPS+1;i++){
            sta $7f8+i
        }
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

        clc
        lda vel_x
        bpl !pos+
        dec p_x_hi+3
!pos:   adc p_x_lo+3
        sta p_x_lo+3
        bcc !nover+
        inc p_x_hi+3
!nover:

yy:
        lda vel_y
        clc
        adc acc_y
        sta vel_y
        lda #2
        sta acc_y

        clc
        lda vel_y
        bpl !pos+
        dec p_y_hi+3
!pos:   adc p_y_lo+3
        sta p_y_lo+3
        bcc !nover+
        inc p_y_hi+3
!nover:

!done:
        rts

position_sprites:
        .for(var i=NUM_PEEPS;i>=0;i--) {
            lda p_x_lo+i // xpos is 16-bit, 9.7 fixed point (9th bit is MSB sprite X)
            asl     // ... carry has the highest bit of our low byte
            lda p_x_hi+i
            rol     // shifts the Carry flag (bit 8) into place, making A the low 8
                    // bits of the 9-bit pixel coordinate
            sta $d000+(i*2)
            rol $d010
            lda p_y_hi+i
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

peeps:

p_dir:  .byte 1,1,0,1
p_x_lo: .fill 4, 0
p_x_hi: .byte $2e, $75, $20, $50
p_x_min:.byte $29, $29, $d
p_x_max:.byte $41, $7d, $21
p_y_lo: .fill 4, 0
p_y_hi: .byte $b5, $35, $75, $75
p_sp:   .byte 25,30,20

grav:   .byte $1
vel_x:  .byte $0
vel_y:  .byte $0

acc_x:  .byte $00
acc_y:  .byte $00

wav_lo: .byte 0
wav_hi: .byte 0

sprite_0:
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
.byte %00000000,%00110000,%00000000
.byte %00000000,%00100000,%00000000
.byte %00000000,%00100000,%00000000
.byte %00000000,%00100000,%00000000
.byte %00000000,%00100000,%00000000
.byte %00000000,%00110000,%00000000

#import "./charset.asm"
#import "./map.asm"
