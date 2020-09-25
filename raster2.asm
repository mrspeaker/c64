            BasicUpstart2(entry)

            .label irqa = $5
            .label irqx = $6
            .label irqy = $7

            .const START_LINE = 8

entry:
                sei
                lda #0
                sta $d020
                sta $d021

                // turn off ROM
                lda #$35
                sta $1

                // disable timer interrupt
                sta $7f
                sta $dc0d
                sta $dd0d

                // enable raster interrupt
                lda $d01a
                ora #1
                sta $d01a

                lda #$4 // turn off screen (just needs bit 4?)
                sta $d011

                lda START_LINE
                sta $d012

                lda #<irq
                ldx #>irq
                sta $fffe
                stx $ffff

                lda $dc0d
                cli
                jmp *
irq:
                sta irqa
                stx irqx
                sty irqy
                inc $d019

                // Wait until it wraps out of view
                ldy #7
                dey
                bne *-1

                // Draw the raster lines
                ldx #8
!:
                lda cols,x
                sta $d020

                // Wait one-line worth of cycles
                ldy #9
                dey
                bne *-1
                nop
                nop
                dex
                bpl !-

                // do it again down the screen
                lda ypos
                clc
                adc #15
                sta ypos
                sta $d012

done:
                lda #$dc0d              // why read dc0d?
                ldy irqy
                ldx irqx
                lda irqa
                rti
cols:
                .byte  0,6,12,15,13,13,15,12,6
ypos:           .byte START_LINE
