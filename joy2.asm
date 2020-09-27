            BasicUpstart2(entry)

entry:
                sei
                jsr init_sprites

                lda #$7f
                sta $dc0d               // Disable CIA #1

                lda #%01110100          // Enable sprite collision irq
                sta $d01a

                lda #<irq
                ldx #>irq
                sta $314
                stx $315

                cli
                lda $d01e
                jmp *

irq:
                dec $d020
                dec $d019
                lda $d01e               // Have to read D01E after dec D019

                pla
                tay
                pla
                tax
                pla
                rti

init_sprites:
                lda #%00000011
                sta $d015
                // load sprite data
                ldx #$40
!:
                lda spr_data,x
                sta $340,x
                dex
                bpl !-

                lda #$340/64
                sta $7f8
                sta $7f9

                // position
                lda #70
                sta $d001
                sta $d002
                sta $d003
                lda #80
                sta $d000
                rts

spr_data:
                .fill 64, $ff
