            BasicUpstart2(init)
init:
                lda #3
                sta $D020
                sta $D021

                jsr load_sprites
                jsr init_irq
loop:
                rts

init_irq:
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
                dec $D019
                lda $D012
                tax
                and #%00010000
                cmp #%00010000
                bne _irq_d
                txa
                sta $D001
                sta $D003
_irq_d:
                jmp $EA81

sprites:
                .import binary "worm.bin"
