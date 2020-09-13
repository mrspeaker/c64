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

                lda #49
                sta $D012

                lda #<irq
                ldx #>irq
                sta $314
                stx $315
                rts

load_sprites:
                lda #%00000011
                sta $D015

                lda #$ff
                sta $D000               // pos
                sta $D002
                lda #$60
                sta $D001
                sta $D003

                lda #%00000010
                sta $D01C               // multicolor
                lda #0
                sta $D027               // spr0 color
                lda #4
                sta $D028               // spr1 color
                lda #13
                sta $D025               // multi1
                lda #7
                sta $D026               // multi2

                lda #$340/64            // mem pointers
                sta $7F8
                lda #$340/64+1
                sta $7f9

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
                sta $D001
                inc $D001
                sta $D003
                inc $D003
                lda spr_off,x
                adc #180
                sta $D000
                sta $D002

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
spr_lines:      .byte 49,72,94,116,138,160,182,204,226
spr_off:        .byte 0,-15,-24,-15,0,15,24,15,0
sprites:
                .import binary "worm.bin"
