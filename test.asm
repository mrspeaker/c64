
            BasicUpstart2(main)

            .const CLS              = $E544
            .const SP0_MEM          = $0340
            .const SP0_DATA_POINTER = $07F8
            .const RASTER_COMPARE   = $D012
            .const BORDER_COLOR     = $D020
            .const BACKGROUND_COLOR = $D021
            .const SCREEN_COLOR     = $0286
            .const SPRITE_X_MSB     = $D010

main:
                sei

                lda #BLACK
                sta BORDER_COLOR
                sta BACKGROUND_COLOR
                lda #WHITE
                sta SCREEN_COLOR

                ldy #%01111111
                sty $dc0d   // Turn off CIAs Timer interrupts
                sty $dd0d   // Turn off CIAs Timer interrupts
                lda $dc0d   // cancel all CIA-IRQs in queue/unprocessed
                lda $dd0d   // cancel all CIA-IRQs in queue/unprocessed

                lda #<irq
                ldx #>irq
                sta $314
                stx $315

                lda #$01
                sta $D01A

                lda #$1f
                sta RASTER_COMPARE
                lda RASTER_COMPARE-1
                and #$7f
                sta RASTER_COMPARE-1

                cli

                jsr CLS

spr:
                lda #%00000001
                sta $D015
                sta $D01D
                sta $D017

                lda #$50
                sta $D000
                lda #0
                sta SPRITE_X_MSB
                lda #SP0_MEM/64
                sta SP0_DATA_POINTER

                ldx #$3e                // 63 bytes - a sprite

dataload:
                lda spr0,x
                sta SP0_MEM,x
                dex
                bne dataload
loop:
                lda #320/2
                sta $D000
                lda #$40
                sta $D001

letterready:
               // ldx #$0
                lda #$1
letters:
                sta $400,x
                inx
                inx
                adc #$01
                cmp #$80
                bcc letters

rast1:
                lda RASTER_COMPARE
                cmp #$80
                bne rast1

sprxmove:
                inc sp0x
                bne sprnowrap
                lda SPRITE_X_MSB // flip msb
                eor #$1
                sta SPRITE_X_MSB
sprnowrap:
                lda sp0x
                sta $D000
                lda #$A0
                sta $D001

                inc BORDER_COLOR
                inc BACKGROUND_COLOR
rast2:
                lda RASTER_COMPARE
                cmp #$82
                bne rast2

                dec BORDER_COLOR
                dec BACKGROUND_COLOR
rast3:
                lda RASTER_COMPARE
                cmp #$f0
                bne rast3

done:
                jmp loop

irq:
                dec $D019
                inc BORDER_COLOR
                lda #$20
                sta RASTER_COMPARE
                lda #<irq2
                ldx #>irq2
                sta $314
                stx $315
                jmp $EA81

irq2:
                dec $D019
                dec BORDER_COLOR
                lda #$1f
                sta RASTER_COMPARE
                lda #<irq
                ldx #>irq
                sta $314
                stx $315

                jmp $EA81

sp0x:           .byte $0

spr1:           .byte 0,127,0,1,255,192,3,255,224,3,231,224
	            .byte 7,217,240,7,223,240,2,217,240,3,231,224
	            .byte 3,255,224,3,255,224,2,255,160,1,127,64
	            .byte 1,62,64,0,156,128,0,156,128,0,73,0,0,73,0,0
	            .byte 62,0,0,62,0,0,62,0,0,28,0

spr2:           .byte 12,0,192,12,0,192,3,3,0,3,3,0
                .byte 15,255,192,15,255,192
                .byte 60,252,240,60,252,240
                .byte 255,255,252,255,255,252
                .byte 207,255,204,207,255,204
                .byte 204,0,204,204,0,204
                .byte 3,207,0,3,207,0
                .byte 0,0,0,0,0,0,0,0,0,0,0,0
                .byte 0,0,0

spr0:
                .byte $00,$00,$00,$00,$00,$00,$00,$00
                .byte $00,$00,$0f,$c0,$00,$3f,$e0,$00
                .byte $7f,$e0,$00,$77,$70,$00,$77,$70
                .byte $00,$7f,$f0,$0c,$7d,$f0,$0e,$1f
                .byte $f0,$0f,$0f,$f0,$0f,$df,$f0,$0f
                .byte $ff,$e0,$0f,$ff,$e0,$07,$ff,$c0
                .byte $07,$ff,$80,$03,$ff,$00,$01,$fc
                .byte $00,$00,$00,$00,$00,$00,$00,$01
