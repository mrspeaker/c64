            BasicUpstart2(main)

            .const SPR_ENABLE = $d015
            .const SPR0_X_POS = $d000
            .const SPR0_Y_POS = $d001
            .const SPR0_DATA_POINTER = $07F8
            .const SPRITE_X_MSB     = $D010
            .const BORDER_COLOR = $d020
            .const BACKGROUND_COLOR = $d021
            .const RASTER_COMPARE = $d012
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
                ldx #7
_spr_m:
                dex
                txa
                asl
                tax
                inc SPR0_Y_POS,x
                lsr
                tax
                inx
                dex
                bne _spr_m
                rts

setup_sprite:
                lda #%11111111
                sta SPR_ENABLE
                ldx #7
_spr:
                dex // offset by 1 so bne works at end

                txa
                sta SPR0_DATA_POINTER,x

                asl // double x for pos pointer
                tax

                asl
                asl
                asl
                adc #$80

                sta SPR0_X_POS,x
                sta SPR0_Y_POS,x

                txa // halve x for next iteration
                lsr
                tax

                inx
                dex
                bne _spr

                rts
