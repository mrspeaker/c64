            BasicUpstart2(entry)

entry:
                jsr init
                jsr init_sprites

                lda #$7f
                sta $dc0d
                lda $dc0d
                lda #1
                sta $d01a
                sta $d019

                lda #40
                sta $d012
                lda $d011
                and #$7f
                sta $d011

                lda #<irq
                sta $314
                lda #>irq
                sta $315

                jmp *

irq:
                dec $d019

                jsr update_sprites
                jsr draw_sprites

                pla
                tya
                pla
                txa
                pla
                rti

init:
                lda #0
                sta $d020
                sta $d021
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

update_sprites:
                // Add signed byte to 16-bit value

                // c n ac       hi       lo
                // - - -------- -------- --------
                // 0            00000001 00000000
                // 0 1 10000001                   ; lda #7f
                //   1                            ; bpl = false
                //              00000000          ; dec x+1
                // 0   10000001                   ; adc x
                //                       10000001 ; sta x ?
                //                                ; bcc = true

                clc
                lda spx
	            bpl !pos+
	            dec x+1
!pos:           adc x
	            sta x
	            bcc !nover+
	            inc x+1
!nover:

                clc
                lda spy
                bpl !pos+
                dec y+1
!pos:
                adc y
                sta y
                bcc !nover+
                inc y+1

!nover:

xrnd:
                lda $dc04
                eor $dc05
                and #%00111111
                tax
                cmp #%00111111
                bne yrnd
                clc
                lda spx
                eor #$ff
                adc #1
                sta spx
                jmp !+
yrnd:
                txa
                cmp #%00111110
                bne !+
                clc
                lda spy
                eor #$ff
                adc #1
                sta spy
!:

                rts

draw_sprites:
                // Sprites are fixed point 9.7 format
                // |16 = MSB|next 8 bits = hi|next 7 bits = fractional|

                // c M hi      8 lo      ; carry | sprite MSB | hi | 8th bit for hi | lo 7bits |
                // - --------- ---------
                // 0 1 0000000 1 0000000 ; init setup.
                // 0           1 0000000 ; lda x
                // 1           0 0000000 ; asl
                // 1 1 0000000           ; lda x+1
                // 1 0 0000001           ; rol (grab 8th bit from lo, put MSB in carry)
                // x = 0000001           ; sta $d000
                // msb = carry           ; rol $d010 (roll MSB into bit #1 of vic)
                lda x
                asl
                lda x+1
                rol
                sta $d000
                rol $d010

                lda y+1
                sta $d001

                rts

x:              .byte $00, $40
y:              .byte $00, $61
spx:            .byte $60
spy:            .byte $70

vx:             .byte $5
vy:             .byte $0


spr:
                .byte $00,$00,$00,$00,$00,$00,$00,$00
                .byte $00,$00,$7c,$00,$01,$83,$00,$02
                .byte $00,$80,$04,$1e,$40,$04,$03,$20
                .byte $08,$03,$20,$08,$01,$90,$08,$00
                .byte $90,$08,$00,$10,$08,$00,$10,$04
                .byte $00,$20,$04,$00,$20,$02,$00,$40
                .byte $01,$81,$80,$00,$7e,$00,$00,$00
                .byte $00,$00,$00,$00,$00,$00,$00,$01
