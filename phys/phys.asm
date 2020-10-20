        BasicUpstart2(entry)

            .const PHYS_REPS = 8

entry:
            jsr init
            jmp *

init:
            lda #0
            sta $d020
            sta $d021

            jsr init_irq
            jsr init_sprites
            rts

init_irq:
            sei
            lda #1
            sta $d01a

            lda #$7f
            sta $dc0d
            lda $dc0d

            lda #20
            sta $d012

            lda #<irq
            ldx #>irq
            sta $314
            stx $315
            cli
            rts

init_sprites:
            lda #%00000001
            sta $d015

            lda #1
            sta $d027

            lda #$340/64
            sta $7f8

            ldx #64
!:
            lda spr,x
            sta $340,x
            dex
            bpl !-

            rts

irq:
            dec $d019
            jsr get_moves
            jsr update_phys
            jsr wall_collisions
            jsr draw_sprites

            pla
            tay
            pla
            tax
            pla
            rti

get_moves:
            lda $dc00
up:         lsr
            bcs down
            ldx #-1
            stx ay
down:       lsr
            bcs left
            ldx #1
            stx ay
left:       lsr
            bcs right
            ldx #-1
            stx ax
right:      lsr
            bcs !done+
            ldx #1
            stx ax
!done:
            rts

update_phys:

xx:
            lda vx
            clc
            adc ax
            sta vx
            lda #0
            sta ax

            ldx #PHYS_REPS
!rep:
            clc
            lda vx
            bpl !pos+
            dec x_hi
!pos:       adc x
            sta x
            bcc !nover+
            inc x_hi
!nover:
            dex
            bpl !rep-

yy:
            lda vy
            clc
            adc ay
            sta vy
            lda #2
            sta ay

            ldx #PHYS_REPS
!rep:
            clc
            lda vy
            bpl !pos+
            dec y_hi
!pos:       adc y
            sta y
            bcc !nover+
            inc y_hi
!nover:
            dex
            bpl !rep-

            rts

wall_collisions:
            clc

            lda x   // 9.7!
            asl
            lda x_hi
            rol
            bcs wall_r
            cmp #20
            bcs wall_t

            // bounce
            clc
            lda vx
            eor #$ff
            adc #1
            sta vx
            jmp wall_t
wall_r:
            cmp #70
            bmi wall_t
            // bounce
            clc
            lda vx
            eor #$ff
            adc #1
            sta vx
wall_t:
            clc
            lda y_hi
            cmp #45
            bcs wall_b
            // bounce
            clc
            lda vy
            eor #$ff
            adc #1
            sta vy
            jmp wall_done
wall_b:
            cmp #240
            bcc wall_done
            // bounce
            clc
            lda vy
            eor #$ff
            adc #1
            sta vy
wall_done:
            rts

draw_sprites:
            // sprites X pos: fixed-point 9.7
            lda x
            asl
            lda x_hi
            rol
            sta $d000
            rol $d010

            lda y_hi
            sta $d001

            rts

x:          .byte 0
x_hi:       .byte 80
y:          .byte 0
y_hi:       .byte 80
vx:         .byte 0
vy:         .byte 0
ax:         .byte 40
ay:         .byte 40

spr:
#import "../res/sprites/bubble.asm"
