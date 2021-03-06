/*
   This is testing reacting to sprite v sprite IRQ.
   Not that you'd really ever want to do that for real
   (just poll $D01e once a frame), but just for testing.

   One thing I discovered: you MUST read $D01e before
   the IRQ will fire, and also must read it after every
   $D019 IRQ ack... to re-enable it.

   The memory map says "Write: Enable further detection
   of sprite-sprite collisions." but I found that it has
   to be a read. (Maybe I misunderstand this)
*/

            BasicUpstart2(entry)

entry:
                sei
                jsr init_sprites

                lda #$7f
                sta $dc0d               // Disable CIA #1

                lda #%11110100          // Enable sprite collision irq
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

                lda $d019
                ora #%00000100
                sta $d019

                // lda #3           // Load/store does not work...
                // sta $d01e
                lda $d01e          // Have to just read it to clear and enable?

                // lda #3
                // sta $d01e

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
