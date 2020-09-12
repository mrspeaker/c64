            BasicUpstart2(init)
init:
                lda #3
                sta $D020
                sta $D021

                lda #%00000011
                sta $D015
                sta $D01D
                sta $D017

                lda #$f0
                sta $D000
                sta $D002
                lda #$40
                sta $D001
                sta $D003
                lda #%00000010
                sta $D01C
                lda #0
                sta $D027
                lda #6
                sta $D028
                lda #2
                sta $D025
                lda #13
                sta $D026

                lda #$340/64
                sta $7F8
                lda #$340/64+1
                sta $7f9

                ldx #64*2
spr:
                lda sprites,x
                sta $340,x
                dex
                bne spr

loop:
                rts

sprites:
                .import binary "worm.bin"
