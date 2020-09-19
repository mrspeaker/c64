            BasicUpstart2(entry)

entry:
                sei
                lda #$7f
                sta $dc0d // turn off CIA timer
//                sta $dd0d
                lda $dc0d

                lda $d01a
                ora #$01
                sta $d01a


                lda #$0b // turn off screen (just needs bit 4?)
                and #$7f // clear high bit
                sta $d011
                lda #$40
                sta $d012


                lda #<irq
                ldx #>irq
                sta $314
                stx $315

                cli
                jmp *

irq:
                dec $d019
                dec $d020

                lda $d012
                clc
                adc #$4
                sta $d012
                bcc !+
                lda #0
                sta $d020
!:

                pla
                tay
                pla
                tax
                pla

                rti
