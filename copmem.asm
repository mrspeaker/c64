/*
   Copy character ROM from ROM bank $D000
   to RAM at $2000.

   Point VIC-II chip at $2000 for characters
*/
            BasicUpstart2(main)
            *=$810

            .const CHAR_ROM          = $D800 // lowercase at 800
            .const CHAR_MEM          = $2000
            .const VIC_CHAR_POINTER  = $D018
            .const BORDER_COLOR      = $D020

main:
                sei

                // Choose bank. Bits #0-2 set bank
                lda $1
                pha
                // unset bit 4 (%0xx makes ROM visible)
                and #%11111011
                sta $1

                // Copy some ROM chars to $2000
                ldy #0
cp:
                lda CHAR_ROM,y
                and #%11101111 // Modify font!
                sta CHAR_MEM,y

                lda CHAR_ROM+$100,y
                and #%11101111
                sta CHAR_MEM+$100,y

                dey
                bne cp

                // Set bank back to RAM
                //lda $1
                //ora #%00000100          // set bit 4
                pla // (testing pha/pla instaead of reset pin 4
                sta $1

                cli

                // Point at char rom
                lda VIC_CHAR_POINTER
                and #%11110001
                ora #%00001000
                sta VIC_CHAR_POINTER

                lda #6
                sta BORDER_COLOR

                rts
