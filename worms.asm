            BasicUpstart2(init)
init:
                sei
                lda #3
                sta $D020
                sta $D021

                jsr load_sprites
                jsr init_irq
                cli
                rts

init_irq:

                lda #%01111111          // disable CIA interrupt
                sta $DC0D

                lda $D01A               // enable raster IRQ
                ora #$01
                sta $D01A

                lda $D011               // clear high bit or raster line
                and #%01111111
                sta $D011
                lda spr_lines
                sta $D012

                lda #<irq
                ldx #>irq
                sta $314
                stx $315
                rts

load_sprites:
                lda #%00011111
                sta $D015

                lda #$ff
                sta $D000               // pos
                sta $D002
                sta $D004
                sta $D006
                sta $D008
                lda #$50
                sta $D001
                sta $D003
                sta $D005
                sta $D007
                sta $D009

                lda #%00000110
                sta $D01C               // multicolor
                lda #0
                sta $D027               // spr0 color
                sta $D029
                lda #4
                sta $D028               // spr1 color
                lda #13
                sta $D025               // multi1
                lda #7
                sta $D026               // multi2

                lda #$340/64            // mem pointers
                sta $7F8
                sta $7fb
                sta $7fc
                lda #$340/64+1
                sta $7f9
                sta $7fa

                ldx #64*2               // load 2 sprites
_load:
                lda sprites,x
                sta $340,x
                dex
                bne _load
                rts

irq:

                inc $D020
                ldx spr_last
                lda spr_lines,x
                // TODO: wait until new D012 then position.
                // would fix jitter
                adc #2 // allow a line! Else, doesn't show
                sta $D001
                sta $D003
                sta $D005
                sta $D007
                sta $D009
                lda spr_off,x
                adc #180
                sta $D000
                sta $D002
                adc #25
                adc spr_off,x
                sta $D004
                lda $D006
                clc
                adc spr_off,x
                asl
                sta $D006

                stx $D025
                inc $D025

                inc spr_off,x

                inc spr_last
                lda spr_last
                cmp #9
                bmi _b
                                        // leave to rom
                ldx #$0
                stx spr_last
                lda spr_lines,x
                sta $D012
                lda #4
                sta $d020
                dec $D019
                jmp $EA31
_b:
                ldx spr_last
                lda spr_lines,x
                sta $D012

_irq_d:
                dec $D019               // clear source of interrupts
                pla
                tay
                pla
                tax
                pla
                rti

spr_last:       .byte 1
spr_lines:      .byte 50,72,94,116,138,160,182,204,226
spr_off:        .byte 0,-15,-24,-15,0,15,24,15,0
sprites:
                .import binary "worm.bin"
