.var picture1 = LoadBinary("untitled.kla", BF_KOALA)

            BasicUpstart2(entry)

entry:
                lda #0
                sta $d021
                sta $d020

                sei

                lda #%01111111
                sta $dc0d
                lda $dc0d

                lda $d01a
                ora #$01
                sta $d01a
                lda $d011
                and #$7f
                sta $d011

                lda #$10
                sta $d012

                lda #<irq
                ldx #>irq
                sta $314
                stx $315

                cli

                lda #$3
                sta $d015

                lda #$b0
                sta $d000
                sta $d001
                sta $d002
                sta $d003

                // nah, dunno why sprites work like this
                lda #$2000/64
                sta $7F8
                sta $7f9


                ldx #0
!:
                lda msg,x
                beq !+
                sta $400+40*13+11,x
                sta $400+40*14+12,x
                sta $400+40*15+13,x
                sta $400+40*16+14,x
                sta $400+40*17+15,x

                inx
                jmp !-
!:
                jmp *


irq:
                dec $d019


                inc $d001
                dec $d003

                lda #$8f
                sta $d012
                lda #<irq2
                ldx #>irq2
                sta $314
                stx $315

                lda #%00111011
                sta $d011
                lda #%00111000
                sta $d018
                lda #%11011000
                sta $d016

                pla
                tay
                pla
                tax
                pla

                rti

irq2:
                dec $d019

                lda #%00011011
                sta $d011
                lda #%00010101
                sta $d018
                lda #%11001000
                sta $d016

                lda $d001
                and #%00001111
                tax
                lda $D016
                and #%11111000
                ora xoff,x
                sta $D016


                lda #$0
                sta $d012
                lda #<irq
                ldx #>irq
                sta $314
                stx $315



                pla
                tay
                pla
                tax
                pla

                rti

msg:            .text "mr speaker rulez"
                .byte 0
xoff:           .byte 0,0,1,1,2,2,3,3,3,3,2,2,1,1,0,0
 * = $0c00 "ScreenRam_1"; screenRam_1: .fill picture1.getScreenRamSize(), picture1.getScreenRam(i)
 * = $1c00 "ColorRam_1"; colorRam_1: .fill picture1.getColorRamSize(), picture1.getColorRam(i)
 * = $2000 "Bitmap_1"; bitMap_1: .fill picture1.getBitmapSize(), picture1.getBitmap(i)
