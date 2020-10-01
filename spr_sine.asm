            BasicUpstart2(entry)

entry:
                lda #0
                sta $d020
                sta $d021

                jsr $e544

                sei
                // Set rasters
                lda #$7f
                sta $dc0d
                lda $d01a
                ora #$01
                sta $d01a

                // raster line
                lda #40
                sta $d012
                lda $d011
                and #$7f
                sta $d011

                lda #<irq
                ldx #>irq
                sta $314
                stx $315

                cli

                jsr init_spr
                jmp *

init_spr:
                lda #$ff
                sta $d015

                ldx #64
!:
                lda spr,x
                sta $340,x
                dex
                bpl !-

                .for(var i=0;i<8;i++) {
                    lda #70+(i*20)
                    sta $d000+i*2
                    sta $d001+i*2
                    lda #$340/64
                    sta $7f8+i
                }
                rts

irq:
                dec $d019
                inc $d020
                dec $d020
                inc $d000
                pla
                tay
                pla
                tax
                pla
                rti

spr:
                .fill 64, $aa

pos_x:          .byte 10,20,30,40,50,60,70,80,90
