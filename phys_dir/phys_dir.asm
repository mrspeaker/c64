        BasicUpstart2(init)

init:
        jsr init_sprites
        jsr init_msg
        jsr init_irq
        jmp *
main:
        jsr get_input
        jsr update_sprites
        jsr wrap_sprites
        jsr draw_sprites
        rts

init_irq:
        sei
        lda #1
        sta $d01a

        lda #$7f
        sta $dc0d
        lda $dc0d

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

init_msg:
        ldx #0
!:
        lda msg,x
        beq !done+
        sta $400,x
        inx
        jmp !-
!done:
        rts

init_sprites:
        lda #1
        sta $d015

        lda #100
        sta $d000
        sta $d001

        lda #$340/64
        sta $7f8

        ldx #64
!:      lda spr,x
        sta $340,x
        dex
        bpl !-
        rts

irq:
        dec $d019
        jsr main
        pla
        tay
        pla
        tax
        pla
        rti

get_input:
        lda $dc00
up:     lsr
        bcs down
down:   lsr
        bcs left
left:   lsr
        bcs right
        dec dir
        dec dir
right:  lsr
        bcs done
        inc dir
        inc dir
done:
        rts

update_sprites:
        // set vy/vx from dir. testing.
        ldx dir
        lda dx,x
        asl
        sta vx
        lda dy,x
        asl
        sta vy

        // Apply vx/vy
        ldx #3
!:      clc
        lda vx
        bpl !pos+
        dec x_hi
!pos:   adc x
        sta x
        bcc !nover+
        inc x_hi
!nover: dex
        bpl !-

        ldx #3
!:      clc
        lda vy
        bpl !pos+
        dec y_hi
!pos:   adc y
        sta y
        bcc !nover+
        inc y_hi
!nover: dex
        bpl !-

        // Timer
        clc
        lda t
        adc #$c0
        sta t
        bcc !+
        //        dec dir
!:
        rts

draw_sprites:
        clc
        lda x
        asl
        lda x_hi
        rol
        sta $d000
        rol $d010

        clc
        lda y
        asl
        lda y_hi
        rol
        sta $d001
        rts

wrap_sprites:
        rts
        clc
        lda x
        asl
        lda x_hi
        rol
        bcc !left+
        cmp #50
        bmi !done+
        dec $d020
        lda #0
        sta x_hi
!left:
        cmp #10
        bpl !done+
        lda #11
        sta x_hi
!done:
        rts

x:      .byte 0
x_hi:   .byte 80
y:      .byte 0
y_hi:   .byte 80

vx:     .byte 0
vy:     .byte 0
dir:    .byte 0

t:      .byte 10

dx:     .fill 256, cos(toRadians((360/256) * i))*15
dy:     .fill 256, sin(toRadians((360/256) * i))*15
msg:    .text "steer with joyport 2"
        .byte 0
spr:
#import "../res/sprites/bubble.asm"
