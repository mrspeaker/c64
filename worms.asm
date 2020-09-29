            BasicUpstart2(init)

            .const SPR_ROWS = 9
init:
                sei
                lda #3
                sta $D020
                sta $D021

                jsr load_sprites
                jsr init_irq
                cli
                rts

init_irq:       {
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
}

load_sprites:   {
                lda #%00111111
                sta $D015

                // X and Y pos
                lda #$ff
                ldx #$50
                .for (var i = 0; i < 6; i++) {
                    sta $D000 + i * 2
                    stx $D001 + i * 2
                }

                lda #%00100110
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
                sta $7fd
                lda #$340/64+2
                sta $7fd

                // Load sprite data
                ldx #64*3
!:
                lda sprites,x
                sta $340,x
                dex
                bne !-
                rts
}

irq:            {
                inc $D020

                ldx spr_last
                lda spr_lines,x
                adc #2                  // allow a couple lines! Else, doesn't show

                // Store Y's
                .for(var i = 0;i < 6; i++) {
                    sta $D001 + i * 2
                }

                // And X's
                lda spr_off,x
                adc #180
                sta $D000
                sta $D002
                adc #25
                adc spr_off,x
                sta $D004

                // Backwards sprite
                lda $D006
                clc
                adc spr_off,x
                asl
                sta $D006

                // Colors
                stx $D025
                inc $D025
                stx $D02B
                rol $D02B

                // Move
                inc spr_off,x
                inc spr_last
                lda spr_last
                cmp #SPR_ROWS
                bmi _not_last
_last_sprite:
                ldx #$0
                stx spr_last
                lda spr_lines,x
                sta $D012
                lda #3
                sta $D020

_chars:
                ldy $dc04
                tya
                eor $dc05
                sta $400,y
                sta $680,y

_text_scr:
                lda $D016
                and #%11111000
                ldx scrx
                ora scrx_off,x
                sta $D016

                lda scrx
                clc
                adc #1
                and #$7
                sta scrx

                dec $D019
                jmp $EA31               // leave to rom
_not_last:
                ldx spr_last
                lda spr_lines,x
                sta $D012

_irq_d:
                dec $D019
                pla
                tay
                pla
                tax
                pla
                rti
}


spr_last:       .byte 1
spr_lines:      .byte 50,72,94,116,138,160,182,204,226
spr_off:        .byte 0,-15,-24,-15,0,15,24,15,0
scrx:           .byte 0
scrx_off:       .byte 0,1,2,3,3,2,1
sprites:
                .import binary "worms_sprites.bin"
                .fill 64, $55
