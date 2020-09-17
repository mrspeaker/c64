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
                dey
                bpl _spr_m
                rts

setup_sprite:
                lda #%11111111
                sta SPR_ENABLE

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
                // center them
                adc #$71

                sta SPR0_X_POS,x
                sta SPR0_Y_POS,x

                txa // halve x for next iteration
                lsr // (after we doubled above for pos)
                tax

                dex
                bpl _spr

                rts
sprdata:
                .fill 64/6, [$aa, $aa, $aa, $55, $55, $55]
