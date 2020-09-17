            BasicUpstart2(main)

            .const SPR_ENABLE = $d015
            .const SPR0_X_POS = $d000
            .const SPR0_Y_POS = $d001
            .const SPR0_DATA_POINTER = $07F8
            .const SPRITE_X_MSB      = $D010
            .const BORDER_COLOR      = $d020
            .const BACKGROUND_COLOR  = $d021
            .const RASTER_COMPARE    = $d012
            .const CLS = $e544

main:
                jsr init
                jsr setup_sprite
loop:
                jsr move_sprites
wait:
                lda RASTER_COMPARE
                bne wait
                jmp loop

init:
                lda #0
                sta BACKGROUND_COLOR
                sta BORDER_COLOR
                sta SPRITE_X_MSB

                jsr CLS
                rts

move_sprites:
                ldy #7
_spr_m:
                tya
                asl
                tax
                inc SPR0_Y_POS,x

                lda SPR0_Y_POS,x
                cmp #$0
                bne !+
_wrap:
                adc $dc04
                eor $dc05
                sta SPR0_X_POS,x
                sta $D027,y
!:
                dey
                bpl _spr_m
                rts

setup_sprite:
                lda #%11111111
                sta SPR_ENABLE

                sta $D01c
                lda #$7
                sta $D025
                lda #$0
                sta $D026

                // copy sprite data
                ldx #64
!:
                lda sprdata,x
                sta $340,x
                dex
                bpl !-

                ldx #7
_spr:
                lda #$340/64
                sta SPR0_DATA_POINTER,x
                txa

                asl // double x for pos pointer
                tax

                // spread them out
                asl
                asl
                asl
                adc $dc04
                eor $dc05
                // center them
                adc #$80

                sta SPR0_X_POS,x
                asl
                asl
                sta SPR0_Y_POS,x

                txa // halve x for next iteration
                lsr // (after we doubled above for pos)
                tax

                dex
                bpl _spr

                rts
sprdata:
                .byte $00,$00,$00,$00,$95,$40,$02,$a9
                .byte $90,$0a,$a9,$54,$0a,$aa,$64,$0a
                .byte $aa,$95,$2a,$aa,$a5,$2a,$aa,$a9
                .byte $3a,$aa,$a6,$3a,$aa,$a9,$3a,$aa
                .byte $a6,$3a,$aa,$a9,$3e,$aa,$a9,$3f
                .byte $aa,$aa,$3f,$ea,$ba,$3b,$ba,$fe
                .byte $3e,$eb,$bc,$0f,$ba,$fc,$0f,$ee
                .byte $f0,$03,$ff,$c0,$00,$00,$00,$83


                .fill 64/6, [$aa, $aa, $aa, $55, $55, $55]
