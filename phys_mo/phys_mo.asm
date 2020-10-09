        BasicUpstart2(entry)

        .const PHYS_REPS = 5

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

        lda #$b0
        sta $d012
        lda $d011
        and #%11111110
        sta $d011

        lda #<irq
        ldx #>irq
        sta $314
        stx $315
        cli
        rts

init_sprites:
        lda #%11111111
        sta $d015

        lda #1
        sta $d027

        lda #$340/64
        .for (var i=0;i<8;i++) {
            sta $7f8+i
        }

        ldx #64
!:
        lda spr,x
        sta $340,x
        dex
        bpl !-

        rts

irq:
       // inc $d020
        dec $d019

        jsr get_moves
        ldx #7
!:
        jsr update_phys
        jsr wall_collisions
        dex
        bpl !-

        jsr draw_sprites
       // dec $d020

        pla
        tay
        pla
        tax
        pla
        rti

get_moves:
        lda $dc00
up:     lsr
        bcs down
        ldx #-3
        .for(var i=0;i<8;i++){
           stx ay+i
        }
down:   lsr
        bcs left
        ldx #1
        .for(var i=0;i<8;i++){
           stx ay+i
        }
left:   lsr
        bcs right
        ldx #-3
         .for(var i=0;i<8;i++){
           stx ax+i
        }
right:  lsr
        bcs !done+
        ldx #3
         .for(var i=0;i<8;i++){
           stx ax+i
        }
!done:
        rts

update_phys:

xx:
        lda vx,x
        clc
        adc ax,x
        sta vx,x
        lda #0
        sta ax,x

        ldy #PHYS_REPS
!rep:
        clc
        lda vx,x
        bpl !pos+
        dec x_hi,x
!pos:   adc x,x
        sta x,x
        bcc !nover+
        inc x_hi,x
!nover:
        dey
        bpl !rep-

yy:
        lda vy,x
        clc
        adc ay,x
        sta vy,x
        lda #2
        sta ay,x

        ldy #PHYS_REPS*2 // um, why * 2?
!rep:
        clc
        lda vy,x
        bpl !pos+
        dec y_hi,x
!pos:   adc y,x
        sta y,x
        bcc !nover+
        inc y_hi,x
!nover:
        dey
        bpl !rep-

friction_y:
        clc
        lda vy,x
        beq !++
        bmi !+
        // pos
        sec
        sbc #2
!:
        // neg
        clc
        adc #1
!:
        sta vy,x

friction_x:
        clc
        lda vx,x
        beq !zero+
        bmi !minus+
        sec
        sbc #2
!minus:
        clc
        adc #1
!zero:
        sta vx,x

        rts

wall_collisions:
        clc

        lda x,x // 9.7!
        asl
        lda x_hi,x
        rol
        bcs wall_r
        cmp #20
        bcs wall_t

        // bounce
        clc
        lda vx,x
        eor #$ff
        adc #1
        sta vx,x
        jmp wall_t
wall_r:
        cmp #70
        bmi wall_t
        // bounce
        clc
        lda vx,x
        eor #$ff
        adc #1
        sta vx,x
wall_t:
        clc
        lda y_hi,x
        cmp #45
        bcs wall_b
        // bounce
        clc
        lda vy,x
        eor #$ff
        adc #1
        sta vy,x
        jmp wall_done
wall_b:
        cmp #230
        bcc wall_done
        // bounce
        clc
        lda vy,x
        eor #$ff
        adc #1
        sta vy,x
        lda #228
        sta y_hi,x
wall_done:
        rts

draw_sprites:
        // sprites X pos: fixed-point 9.7
        lda #%00000000
        sta $d010
        .for (var i = 7; i >= 0; i--) {
            lda x+i
            asl
            lda x_hi+i
            rol
            sta $d000+i*2
            rol $d010

            lda y_hi+i
            sta $d001+i*2
        }
        rts

x:      .fill 8, 0
x_hi:   .fill 8, i*10+50
y:      .fill 8, 0
y_hi:   .fill 8, round(random()*20)+60
vx:     .fill 8, 0
vy:     .fill 8, 0
ax:     .fill 8, round(random()*70)-35
ay:     .fill 8, round(random()*40)-20


spr:
#import "../res/sprites/bubble.asm"
