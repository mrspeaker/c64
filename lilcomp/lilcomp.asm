        BasicUpstart2(entry)


        .label ADDR_CHAR_MAP_DATA         = $1800 // label = 'map_data'            (size = $03e8).
        .label ADDR_CHAR_MAP_COLOUR_DATA  = $1be8 // label = 'map_colour_data'     (size = $03e8).
        .label ADDR_CHARSET_DATA          = $2800 // label = 'charset_data'        (size = $0800).

        .label tmp = $fc

        .const NUM_PEEPS = 3
entry:

        jsr init
        jsr copy_chars
                jsr draw_screen
                jsr init_sprites
loop:

                // TODO: just make this an IRQ
                lda $d012
                cmp #10
                bne loop

                jsr update_peeps
                jsr update_ball
                jsr position_sprites
                jsr rotate_water

!:
                lda $d012
                cmp #11
                bne !-

                jmp loop

init:
                lda #$0
                sta $d020
                sta $d021
                rts

init_sprites:
                lda #%00001111
                sta $d015
                sta $d01c

                lda #$9
                sta $d025
                lda #$4
                sta $d026
                lda #1
                sta $d027
                sta $d028
                sta $d029
                lda #7
                sta $d02a

                ldx #64
!:
                lda sprite_0,x
                sta $340,x
                dex
                bpl !-

                lda #$340/64
                sta $7f8
                sta $7f9
                sta $7fa
                sta $7fb

                rts


copy_chars:
                lda $d018
                and #%11110001
                ora #%00001010          // $2800
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
                bmi don
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
                bpl don
                lda #1
                sta p_dir,x
don:
                dex
                bpl !-
                rts

update_ball:

set_x:
                lda b_vel_x
                beq update_grav

	            clc
	            bpl !pos+
	            dec p_x_hi+3
!pos:           adc p_x_lo+3
	            sta p_x_lo+3
	            bcc !nover+
	            inc p_x_hi+3
!nover:

friction:
                dec b_vel_x
                bne update_grav
                lda #$ff
                sta b_vel_x

update_grav:
                // lda #$ff
                // sec
                // sbc b_vel_x
                // lsr
                // lsr
                // lsr
                // lsr
                // sta grav

set_y:
                lda b_vel_y
gravity:
                clc
                adc grav
                sta b_vel_y

                ldx #7  // Apply it over n over....
!:              lda b_vel_y
	            clc
	            bpl !pos+
	            dec p_y+3
!pos:           adc p_y_lo+3
	            sta p_y_lo+3
	            bcc !nover+
	            inc p_y+3
!nover:
                dex
                bne !-
done:
                rts

position_sprites:
                .for(var i=NUM_PEEPS;i>=0;i--) {
                    lda p_x_lo+i        // xpos is 16-bit, 9.7 fixed point (9th bit is MSB sprite X)
                    asl                 // ... carry has the highest bit of our low byte
                    lda p_x_hi+i
                    rol                 // shifts the Carry flag (bit 8) into place, making A the low 8
                                        // bits of the 9-bit pixel coordinate
                    sta $d000+(i*2)
                    rol $d010
                    lda p_y+i
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



get_tile:
                // for spr x
                lda p_x_hi,x
                lsr                     // /2
                lsr                     //4
                lsr                     //8
                tay
                lda p_y
                lsr
                lsr
                lsr
                /// map_data + (a * 4 + x)

peeps:

p_dir:          .byte 1,1,0
p_x_lo:         .byte 0,0,0,0
p_x_hi:         .byte $2e, $75, $20, $50
p_x_min:        .byte $29, $29, $12
p_x_max:        .byte $41, $7d, $25
p_y:            .byte $b5, $35, $75, $70
p_y_lo:         .byte 0,0,0,0
p_sp:           .byte 25,30,20

grav:           .byte $1
b_vel_x:        .byte $ff
b_vel_y:        .byte $ff/2

b_acc_x:        .byte $0
b_acc_y:        .byte %0

wav_lo:         .byte 0
wav_hi:         .byte 0

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


scr_lookup:
                .byte $0400, $0440

* =  ADDR_CHARSET_DATA
charset_data:

.byte $00,$e0,$f8,$1c,$0e,$0c,$0e,$0a,$18,$3c,$66,$7e,$66,$66,$66,$00
.byte $7c,$66,$66,$7c,$66,$66,$7c,$00,$3c,$66,$60,$60,$60,$66,$3c,$00
.byte $78,$6c,$66,$66,$66,$6c,$78,$00,$7e,$60,$60,$78,$60,$60,$7e,$00
.byte $7e,$60,$60,$78,$60,$60,$60,$00,$3c,$66,$60,$6e,$66,$66,$3c,$00
.byte $66,$66,$66,$7e,$66,$66,$66,$00,$3c,$18,$18,$18,$18,$18,$3c,$00
.byte $1e,$0c,$0c,$0c,$0c,$6c,$38,$00,$66,$6c,$78,$70,$78,$6c,$66,$00
.byte $60,$60,$60,$60,$60,$60,$7e,$00,$63,$77,$7f,$6b,$63,$63,$63,$00
.byte $66,$76,$7e,$7e,$6e,$66,$66,$00,$3c,$66,$66,$66,$66,$66,$3c,$00
.byte $7c,$66,$66,$7c,$60,$60,$60,$00,$3c,$66,$66,$66,$66,$3c,$0e,$00
.byte $7c,$66,$66,$7c,$78,$6c,$66,$00,$3c,$66,$60,$3c,$06,$66,$3c,$00
.byte $7e,$18,$18,$18,$18,$18,$18,$00,$66,$66,$66,$66,$66,$66,$3c,$00
.byte $66,$66,$66,$66,$66,$3c,$18,$00,$63,$63,$63,$6b,$7f,$77,$63,$00
.byte $66,$66,$3c,$18,$3c,$66,$66,$00,$66,$66,$66,$3c,$18,$18,$18,$00
.byte $7e,$06,$0c,$18,$30,$60,$7e,$00,$6c,$34,$08,$18,$18,$30,$24,$5a
.byte $0c,$12,$30,$7c,$30,$62,$fc,$00,$3c,$0c,$0c,$0c,$0c,$0c,$3c,$00
.byte $00,$18,$3c,$7e,$18,$18,$18,$18,$00,$04,$01,$10,$05,$10,$05,$10
.byte $00,$00,$00,$00,$00,$00,$00,$00,$18,$18,$18,$18,$00,$00,$18,$00
.byte $66,$66,$66,$00,$00,$00,$00,$00,$66,$66,$ff,$66,$ff,$66,$66,$00
.byte $20,$80,$20,$08,$40,$08,$20,$80,$62,$66,$0c,$18,$30,$66,$46,$00
.byte $00,$06,$1f,$38,$30,$70,$30,$70,$06,$0c,$18,$00,$00,$00,$00,$00
.byte $0c,$18,$30,$30,$30,$18,$0c,$00,$30,$18,$0c,$0c,$0c,$18,$30,$00
.byte $00,$66,$3c,$ff,$3c,$66,$00,$00,$00,$18,$18,$7e,$18,$18,$00,$00
.byte $00,$00,$00,$00,$00,$18,$18,$30,$00,$00,$00,$7e,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$18,$18,$00,$00,$03,$06,$0c,$18,$30,$60,$00
.byte $3c,$66,$6e,$76,$66,$66,$3c,$00,$18,$18,$38,$18,$18,$18,$7e,$00
.byte $3c,$66,$06,$0c,$30,$60,$7e,$00,$3c,$66,$06,$1c,$06,$66,$3c,$00
.byte $06,$0e,$1e,$66,$7f,$06,$06,$00,$7e,$60,$7c,$06,$06,$66,$3c,$00
.byte $3c,$66,$60,$7c,$66,$66,$3c,$00,$7e,$66,$0c,$18,$18,$18,$18,$00
.byte $3c,$66,$66,$3c,$66,$66,$3c,$00,$3c,$66,$66,$3e,$06,$66,$3c,$00
.byte $00,$00,$18,$00,$00,$18,$00,$00,$00,$00,$18,$00,$00,$18,$18,$30
.byte $0e,$18,$30,$60,$30,$18,$0e,$00,$00,$00,$7e,$00,$7e,$00,$00,$00
.byte $70,$18,$0c,$06,$0c,$18,$70,$00,$3c,$66,$06,$0c,$18,$00,$18,$00
.byte $00,$00,$00,$00,$00,$c1,$be,$80,$00,$00,$00,$5c,$aa,$5d,$f7,$ba
.byte $18,$18,$18,$18,$18,$18,$18,$18,$00,$00,$00,$ff,$ff,$00,$00,$00
.byte $00,$00,$00,$00,$00,$01,$02,$04,$00,$00,$00,$00,$00,$80,$c0,$a0
.byte $4b,$f7,$ef,$55,$00,$00,$00,$00,$30,$30,$30,$30,$30,$30,$30,$30
.byte $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$ec,$d2,$3f,$ff,$ff,$bd,$f7,$da
.byte $18,$18,$1c,$0f,$07,$00,$00,$00,$18,$18,$38,$f0,$e0,$00,$00,$00
.byte $c0,$c0,$c0,$c0,$c0,$c0,$ff,$ff,$c0,$e0,$70,$38,$1c,$0e,$07,$03
.byte $03,$07,$0e,$1c,$38,$70,$e0,$c0,$ff,$ff,$c0,$c0,$c0,$c0,$c0,$c0
.byte $ff,$ff,$03,$03,$03,$03,$03,$03,$ed,$d2,$3f,$ff,$ff,$bd,$f7,$da
.byte $00,$00,$00,$00,$00,$00,$00,$fe,$36,$7f,$7f,$7f,$3e,$1c,$08,$00
.byte $60,$60,$60,$60,$60,$60,$60,$60,$2d,$52,$3f,$ff,$ff,$bd,$f7,$5a
.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$be,$55,$aa,$d5,$ff,$ff,$ff,$7e
.byte $18,$18,$66,$66,$18,$18,$3c,$00,$06,$06,$06,$06,$06,$06,$06,$06
.byte $08,$1c,$3e,$7f,$3e,$1c,$08,$00,$18,$18,$18,$ff,$ff,$18,$18,$18
.byte $c0,$c0,$30,$30,$c0,$c0,$30,$30,$18,$18,$18,$18,$18,$18,$18,$18
.byte $00,$00,$03,$3e,$76,$36,$36,$00,$ff,$7f,$3f,$1f,$0f,$07,$03,$01
.byte $00,$00,$00,$00,$00,$00,$00,$00,$ff,$ff,$e7,$ff,$fe,$fe,$fc,$f0
.byte $00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$00,$00,$ff,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0
.byte $cc,$cc,$33,$33,$cc,$cc,$33,$33,$03,$03,$03,$03,$03,$03,$03,$03
.byte $00,$00,$00,$00,$cc,$cc,$33,$33,$ff,$fe,$fc,$f8,$f0,$e0,$c0,$80
.byte $03,$03,$03,$03,$03,$03,$03,$03,$18,$18,$18,$1f,$1f,$18,$18,$18
.byte $00,$00,$00,$00,$0f,$0f,$0f,$0f,$18,$18,$18,$1f,$1f,$00,$00,$00
.byte $00,$00,$00,$f8,$f8,$18,$18,$18,$00,$00,$00,$00,$00,$00,$ff,$ff
.byte $00,$00,$00,$1f,$1f,$18,$18,$18,$18,$18,$18,$ff,$ff,$00,$00,$00
.byte $00,$00,$00,$ff,$ff,$18,$18,$18,$18,$18,$18,$f8,$f8,$18,$18,$18
.byte $c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$1c,$00,$38,$00,$1c,$00,$38,$00
.byte $ff,$ff,$fd,$7f,$77,$3f,$1f,$07,$ff,$ff,$00,$00,$00,$00,$00,$00
.byte $ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$ff,$ff,$ff
.byte $03,$03,$03,$03,$03,$03,$ff,$ff,$00,$00,$00,$00,$f0,$f0,$f0,$f0
.byte $0f,$0f,$0f,$0f,$00,$00,$00,$00,$18,$18,$18,$f8,$f8,$00,$00,$00
.byte $f0,$f0,$f0,$f0,$00,$00,$00,$00,$f0,$f0,$f0,$f0,$0f,$0f,$0f,$0f
.byte $c3,$99,$91,$91,$9f,$99,$c3,$ff,$e7,$c3,$99,$81,$99,$99,$99,$ff
.byte $83,$99,$99,$83,$99,$99,$83,$ff,$c3,$99,$9f,$9f,$9f,$99,$c3,$ff
.byte $87,$93,$99,$99,$99,$93,$87,$ff,$81,$9f,$9f,$87,$9f,$9f,$81,$ff
.byte $81,$9f,$9f,$87,$9f,$9f,$9f,$ff,$c3,$99,$9f,$91,$99,$99,$c3,$ff
.byte $99,$99,$99,$81,$99,$99,$99,$ff,$c3,$e7,$e7,$e7,$e7,$e7,$c3,$ff
.byte $e1,$f3,$f3,$f3,$f3,$93,$c7,$ff,$99,$93,$87,$8f,$87,$93,$99,$ff
.byte $9f,$9f,$9f,$9f,$9f,$9f,$81,$ff,$9c,$88,$80,$94,$9c,$9c,$9c,$ff
.byte $99,$89,$81,$81,$91,$99,$99,$ff,$c3,$99,$99,$99,$99,$99,$c3,$ff
.byte $83,$99,$99,$83,$9f,$9f,$9f,$ff,$c3,$99,$99,$99,$99,$c3,$f1,$ff
.byte $83,$99,$99,$83,$87,$93,$99,$ff,$c3,$99,$9f,$c3,$f9,$99,$c3,$ff
.byte $81,$e7,$e7,$e7,$e7,$e7,$e7,$ff,$99,$99,$99,$99,$99,$99,$c3,$ff
.byte $99,$99,$99,$99,$99,$c3,$e7,$ff,$9c,$9c,$9c,$94,$80,$88,$9c,$ff
.byte $99,$99,$c3,$e7,$c3,$99,$99,$ff,$99,$99,$99,$c3,$e7,$e7,$e7,$ff
.byte $81,$f9,$f3,$e7,$cf,$9f,$81,$ff,$c3,$cf,$cf,$cf,$cf,$cf,$c3,$ff
.byte $f3,$ed,$cf,$83,$cf,$9d,$03,$ff,$c3,$f3,$f3,$f3,$f3,$f3,$c3,$ff
.byte $ff,$e7,$c3,$81,$e7,$e7,$e7,$e7,$ff,$ef,$cf,$80,$80,$cf,$ef,$ff
.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$e7,$e7,$e7,$e7,$ff,$ff,$e7,$ff
.byte $99,$99,$99,$ff,$ff,$ff,$ff,$ff,$99,$99,$00,$99,$00,$99,$99,$ff
.byte $e7,$c1,$9f,$c3,$f9,$83,$e7,$ff,$9d,$99,$f3,$e7,$cf,$99,$b9,$ff
.byte $c3,$99,$c3,$c7,$98,$99,$c0,$ff,$f9,$f3,$e7,$ff,$ff,$ff,$ff,$ff
.byte $f3,$e7,$cf,$cf,$cf,$e7,$f3,$ff,$cf,$e7,$f3,$f3,$f3,$e7,$cf,$ff
.byte $ff,$99,$c3,$00,$c3,$99,$ff,$ff,$ff,$e7,$e7,$81,$e7,$e7,$ff,$ff
.byte $ff,$ff,$ff,$ff,$ff,$e7,$e7,$cf,$ff,$ff,$ff,$81,$ff,$ff,$ff,$ff
.byte $ff,$ff,$ff,$ff,$ff,$e7,$e7,$ff,$ff,$fc,$f9,$f3,$e7,$cf,$9f,$ff
.byte $c3,$99,$91,$89,$99,$99,$c3,$ff,$e7,$e7,$c7,$e7,$e7,$e7,$81,$ff
.byte $c3,$99,$f9,$f3,$cf,$9f,$81,$ff,$c3,$99,$f9,$e3,$f9,$99,$c3,$ff
.byte $f9,$f1,$e1,$99,$80,$f9,$f9,$ff,$81,$9f,$83,$f9,$f9,$99,$c3,$ff
.byte $c3,$99,$9f,$83,$99,$99,$c3,$ff,$81,$99,$f3,$e7,$e7,$e7,$e7,$ff
.byte $c3,$99,$99,$c3,$99,$99,$c3,$ff,$c3,$99,$99,$c1,$f9,$99,$c3,$ff
.byte $ff,$ff,$e7,$ff,$ff,$e7,$ff,$ff,$ff,$ff,$e7,$ff,$ff,$e7,$e7,$cf
.byte $f1,$e7,$cf,$9f,$cf,$e7,$f1,$ff,$ff,$ff,$81,$ff,$81,$ff,$ff,$ff
.byte $8f,$e7,$f3,$f9,$f3,$e7,$8f,$ff,$c3,$99,$f9,$f3,$e7,$ff,$e7,$ff
.byte $ff,$ff,$ff,$00,$00,$ff,$ff,$ff,$f7,$e3,$c1,$80,$80,$e3,$c1,$ff
.byte $e7,$e7,$e7,$e7,$e7,$e7,$e7,$e7,$ff,$ff,$ff,$00,$00,$ff,$ff,$ff
.byte $ff,$ff,$00,$00,$ff,$ff,$ff,$ff,$ff,$00,$00,$ff,$ff,$ff,$ff,$ff
.byte $ff,$ff,$ff,$ff,$00,$00,$ff,$ff,$cf,$cf,$cf,$cf,$cf,$cf,$cf,$cf
.byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$ff,$ff,$ff,$1f,$0f,$c7,$e7,$e7
.byte $e7,$e7,$e3,$f0,$f8,$ff,$ff,$ff,$e7,$e7,$c7,$0f,$1f,$ff,$ff,$ff
.byte $3f,$3f,$3f,$3f,$3f,$3f,$00,$00,$3f,$1f,$8f,$c7,$e3,$f1,$f8,$fc
.byte $fc,$f8,$f1,$e3,$c7,$8f,$1f,$3f,$00,$00,$3f,$3f,$3f,$3f,$3f,$3f
.byte $00,$00,$fc,$fc,$fc,$fc,$fc,$fc,$ff,$c3,$81,$81,$81,$81,$c3,$ff
.byte $ff,$ff,$ff,$ff,$ff,$00,$00,$ff,$c9,$80,$80,$80,$c1,$e3,$f7,$ff
.byte $9f,$9f,$9f,$9f,$9f,$9f,$9f,$9f,$ff,$ff,$ff,$f8,$f0,$e3,$e7,$e7
.byte $3c,$18,$81,$c3,$c3,$81,$18,$3c,$ff,$c3,$81,$99,$99,$81,$c3,$ff
.byte $e7,$e7,$99,$99,$e7,$e7,$c3,$ff,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9
.byte $f7,$e3,$c1,$80,$c1,$e3,$f7,$ff,$e7,$e7,$e7,$00,$00,$e7,$e7,$e7
.byte $3f,$3f,$cf,$cf,$3f,$3f,$cf,$cf,$e7,$e7,$e7,$e7,$e7,$e7,$e7,$e7
.byte $ff,$ff,$fc,$c1,$89,$c9,$c9,$ff,$00,$80,$c0,$e0,$f0,$f8,$fc,$fe
.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
.byte $ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff
.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$3f,$3f,$3f,$3f,$3f,$3f,$3f,$3f
.byte $33,$33,$cc,$cc,$33,$33,$cc,$cc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc
.byte $ff,$ff,$ff,$ff,$33,$33,$cc,$cc,$00,$01,$03,$07,$0f,$1f,$3f,$7f
.byte $fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$e7,$e7,$e7,$e0,$e0,$e7,$e7,$e7
.byte $ff,$ff,$ff,$ff,$f0,$f0,$f0,$f0,$e7,$e7,$e7,$e0,$e0,$ff,$ff,$ff
.byte $ff,$ff,$ff,$07,$07,$e7,$e7,$e7,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00
.byte $ff,$ff,$ff,$e0,$e0,$e7,$e7,$e7,$e7,$e7,$e7,$00,$00,$ff,$ff,$ff
.byte $ff,$ff,$ff,$00,$00,$e7,$e7,$e7,$e7,$e7,$e7,$07,$07,$e7,$e7,$e7
.byte $3f,$3f,$3f,$3f,$3f,$3f,$3f,$3f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f
.byte $f8,$f8,$f8,$f8,$f8,$f8,$f8,$f8,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff
.byte $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00
.byte $fc,$fc,$fc,$fc,$fc,$fc,$00,$00,$ff,$ff,$ff,$ff,$0f,$0f,$0f,$0f
.byte $f0,$f0,$f0,$f0,$ff,$ff,$ff,$ff,$e7,$e7,$e7,$07,$07,$ff,$ff,$ff
.byte $0f,$0f,$0f,$0f,$ff,$ff,$ff,$ff,$0f,$0f,$0f,$0f,$f0,$f0,$f0,$f0


// MAP DATA : 1 (40x25) map : total size is 1000 ($03e8) bytes.

* =  ADDR_CHAR_MAP_DATA
map_data:

.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$41,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$41,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$1b,$20,$20,$20
.byte $41,$20,$44,$40,$40,$40,$40,$40,$45,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$55,$51,$57,$51,$51,$51,$20,$20,$20,$20,$20,$20,$20,$20
.byte $55,$51,$51,$51,$51,$51,$51,$51,$51,$51,$49,$46,$46,$46,$46,$46
.byte $55,$51,$51,$51,$51,$49,$20,$20,$20,$20,$20,$56,$57,$56,$56,$56
.byte $20,$20,$20,$20,$20,$41,$20,$20,$20,$76,$56,$56,$56,$56,$56,$56
.byte $56,$61,$20,$20,$20,$20,$20,$20,$20,$76,$56,$56,$61,$20,$20,$20
.byte $20,$20,$20,$76,$57,$56,$56,$56,$20,$20,$20,$55,$51,$49,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$57,$20,$20,$20
.byte $20,$20,$20,$75,$56,$56,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$41,$20,$20
.byte $20,$20,$20,$20,$57,$20,$20,$20,$20,$20,$20,$75,$76,$56,$51,$51
.byte $51,$51,$57,$51,$51,$49,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$1b,$20,$20,$20,$20,$20,$55,$57,$49,$20,$20
.byte $20,$20,$20,$75,$20,$20,$76,$56,$56,$56,$57,$56,$61,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$55,$51,$51,$49,$20,$20
.byte $41,$20,$20,$56,$56,$56,$20,$20,$20,$20,$20,$75,$20,$20,$20,$20
.byte $20,$76,$57,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$41,$20
.byte $20,$20,$20,$76,$56,$56,$51,$51,$51,$49,$20,$76,$56,$61,$20,$20
.byte $20,$20,$20,$75,$20,$20,$20,$20,$20,$20,$57,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$1b,$20,$20,$20,$20,$20,$56,$56,$56,$56
.byte $56,$20,$20,$20,$20,$20,$20,$20,$20,$55,$51,$51,$51,$51,$49,$20
.byte $20,$20,$57,$20,$20,$20,$20,$20,$55,$51,$51,$51,$51,$51,$51,$49
.byte $20,$20,$20,$20,$56,$56,$56,$56,$56,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$76,$56,$56,$61,$20,$20,$20,$55,$57,$49,$20,$20,$20,$20
.byte $75,$76,$56,$56,$56,$56,$61,$20,$20,$20,$20,$20,$76,$56,$56,$56
.byte $56,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$56,$56,$20,$20,$20
.byte $20,$56,$56,$56,$20,$20,$20,$20,$75,$20,$56,$56,$56,$56,$20,$20
.byte $20,$20,$20,$20,$20,$56,$56,$56,$61,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$56,$56,$20,$20,$20,$20,$76,$56,$61,$20,$20,$20,$20
.byte $75,$20,$56,$56,$56,$56,$20,$20,$20,$20,$20,$20,$20,$76,$56,$61
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$55,$56,$56,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$55,$55,$51,$51,$56,$56,$56,$61,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$56,$56,$56,$49,$20,$20,$20,$20,$20,$20,$20,$20,$75,$76
.byte $56,$56,$56,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$56,$56,$56,$56,$20,$20
.byte $20,$20,$20,$20,$20,$20,$75,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$41,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$76,$56,$56,$56,$20,$20,$20,$20,$20,$41,$20,$20,$75,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$26,$00,$55
.byte $49,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$76,$56,$61,$20,$20
.byte $55,$51,$51,$51,$51,$51,$49,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$41,$20,$20,$55,$51,$51,$56,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$75,$56,$56,$56,$56,$61,$20,$20
.byte $20,$20,$20,$20,$20,$55,$51,$51,$51,$51,$51,$51,$56,$56,$56,$56
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$41,$20,$20
.byte $75,$56,$56,$56,$56,$20,$20,$20,$20,$20,$20,$20,$20,$20,$76,$56
.byte $56,$56,$56,$56,$56,$56,$56,$61,$20,$20,$20,$20,$20,$20,$20,$20
.byte $41,$20,$20,$20,$20,$1b,$20,$20,$75,$56,$56,$56,$61,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$51,$51,$51,$51,$51,$51,$51,$51
.byte $51,$56,$56,$56,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20

//  MAP COLOUR DATA : 1 (40x25) map : total size is 1000 ($03e8) bytes.

* =  ADDR_CHAR_MAP_COLOUR_DATA
map_colour_data:

.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
.byte $01,$01,$01,$01,$0d,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
.byte $01,$01,$01,$0b,$0b,$0b,$01,$01,$01,$01,$01,$0d,$01,$01,$01,$01
.byte $01,$01,$0e,$0e,$0e,$01,$01,$01,$01,$01,$01,$01,$08,$01,$01,$01
.byte $0d,$01,$02,$02,$02,$02,$02,$02,$02,$07,$07,$0b,$0b,$0b,$07,$07
.byte $07,$07,$05,$05,$0e,$05,$05,$05,$01,$01,$0e,$0e,$0e,$0e,$0e,$0e
.byte $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$02,$02,$02,$02,$02
.byte $05,$05,$05,$05,$05,$05,$07,$07,$07,$07,$0e,$09,$0e,$09,$09,$09
.byte $01,$01,$0e,$0e,$01,$0d,$0b,$0e,$05,$09,$09,$09,$09,$09,$09,$08
.byte $08,$0a,$02,$0b,$01,$01,$01,$01,$05,$09,$09,$08,$0a,$07,$01,$01
.byte $01,$01,$0e,$08,$0e,$08,$08,$08,$01,$01,$0e,$05,$05,$05,$0b,$0e
.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$0b,$01,$01,$01,$01
.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0e,$01,$0e,$01,$0e,$01
.byte $01,$01,$0e,$0b,$09,$08,$0b,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$01
.byte $01,$01,$02,$0b,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0d,$01,$01
.byte $01,$01,$01,$01,$0e,$0b,$01,$01,$01,$01,$0e,$0c,$09,$08,$05,$05
.byte $05,$05,$0e,$05,$05,$05,$0e,$01,$01,$01,$02,$0b,$01,$01,$01,$01
.byte $01,$01,$01,$01,$01,$08,$01,$01,$01,$01,$01,$05,$0e,$05,$01,$01
.byte $01,$01,$0e,$0c,$01,$01,$09,$09,$09,$09,$0e,$08,$08,$05,$0e,$0e
.byte $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$01,$05,$05,$05,$05,$01,$01
.byte $0d,$01,$01,$09,$09,$08,$01,$01,$01,$0e,$0e,$0c,$0e,$0e,$01,$01
.byte $01,$08,$0e,$08,$09,$05,$0e,$01,$01,$01,$02,$0b,$0b,$01,$0d,$01
.byte $01,$01,$05,$09,$09,$09,$05,$05,$05,$05,$01,$08,$08,$0a,$01,$01
.byte $01,$0c,$0c,$0c,$0c,$0c,$0c,$0e,$01,$01,$0e,$01,$01,$01,$0e,$01
.byte $01,$01,$02,$0b,$09,$01,$08,$01,$01,$01,$05,$09,$09,$08,$09,$09
.byte $08,$01,$01,$06,$01,$01,$01,$01,$01,$05,$05,$05,$05,$05,$05,$0e
.byte $01,$01,$0e,$0b,$01,$01,$0e,$01,$05,$05,$05,$05,$05,$05,$05,$05
.byte $01,$01,$05,$09,$09,$08,$08,$08,$0a,$09,$01,$06,$01,$01,$01,$01
.byte $01,$05,$09,$09,$08,$08,$05,$05,$01,$05,$0e,$05,$01,$01,$0e,$01
.byte $0b,$09,$09,$09,$09,$08,$08,$05,$01,$01,$01,$09,$09,$08,$08,$08
.byte $0a,$09,$09,$06,$01,$01,$01,$01,$01,$01,$05,$09,$08,$09,$0e,$01
.byte $01,$09,$09,$08,$01,$01,$0e,$01,$0c,$01,$09,$08,$08,$0a,$08,$05
.byte $01,$01,$01,$09,$09,$09,$08,$08,$0a,$09,$09,$06,$01,$01,$01,$01
.byte $01,$01,$01,$09,$08,$09,$0e,$01,$01,$08,$08,$0a,$09,$01,$01,$01
.byte $0c,$09,$09,$08,$08,$0a,$09,$01,$01,$01,$01,$09,$09,$09,$08,$0a
.byte $09,$09,$09,$06,$01,$01,$01,$01,$01,$01,$05,$09,$08,$09,$0e,$09
.byte $01,$09,$09,$01,$01,$01,$05,$05,$05,$05,$09,$08,$08,$0a,$09,$09
.byte $09,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$06,$01,$01,$01,$01
.byte $01,$01,$09,$09,$08,$05,$0e,$09,$01,$01,$01,$09,$01,$01,$0b,$09
.byte $09,$09,$08,$08,$01,$01,$01,$01,$01,$01,$01,$06,$06,$06,$06,$06
.byte $06,$06,$06,$06,$01,$01,$01,$01,$01,$01,$09,$08,$08,$08,$0e,$09
.byte $01,$01,$01,$09,$01,$01,$0c,$01,$01,$01,$01,$01,$06,$01,$01,$01
.byte $01,$01,$01,$01,$01,$01,$01,$0d,$01,$01,$01,$06,$09,$01,$01,$01
.byte $01,$01,$09,$08,$08,$0a,$0e,$09,$01,$01,$01,$0d,$05,$01,$0c,$0e
.byte $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$01,$01,$01,$05,$06,$06,$05
.byte $05,$01,$01,$06,$01,$01,$01,$01,$01,$01,$09,$09,$0a,$0a,$01,$01
.byte $05,$05,$05,$05,$05,$05,$05,$01,$01,$06,$06,$01,$06,$01,$01,$01
.byte $01,$0d,$01,$01,$05,$05,$05,$09,$01,$01,$01,$01,$01,$01,$01,$01
.byte $01,$01,$01,$01,$01,$01,$01,$01,$0b,$09,$09,$09,$08,$08,$05,$01
.byte $01,$06,$06,$01,$06,$05,$05,$05,$05,$05,$05,$05,$09,$09,$09,$0a
.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0d,$01,$01
.byte $0c,$09,$08,$08,$08,$09,$05,$01,$01,$06,$06,$01,$06,$09,$09,$09
.byte $09,$09,$09,$09,$08,$08,$0a,$0a,$01,$01,$01,$01,$01,$01,$01,$01
.byte $0d,$01,$01,$01,$0d,$08,$01,$01,$0c,$09,$08,$08,$0a,$01,$01,$01
.byte $01,$06,$06,$01,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
.byte $01,$01,$01,$01,$01,$01,$01,$01,$05,$05,$05,$05,$05,$05,$05,$05
.byte $05,$09,$08,$0a,$01,$01,$01,$01,$01,$06,$06,$06,$06,$06,$06,$06
.byte $06,$06,$06,$06,$06,$06,$06,$06,$06,$01,$01,$01,$01,$01,$01,$01
.byte $09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$08,$0a,$01,$01,$01,$01
.byte $01,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
.byte $06,$01,$01,$01,$01,$01,$01,$01