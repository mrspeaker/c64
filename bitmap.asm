.var picture1 = LoadBinary("mrspeaker1.kla", BF_KOALA)
.var music = LoadSid("gorf.sid")

            BasicUpstart2(entry)

            .const SCR_ROW = 18

entry:
                lda #0
                sta $d021
                sta $d020

            sei

            jsr music.init

                lda #%01111111          // disable CIA timer
                sta $dc0d
                lda $dc0d

                lda $d01a               // enable raster irq
                ora #$01
                sta $d01a

                lda #$10                // set raster line
                sta $d012
                lda $d011               // high bit of raster dest
                and #$7f
                sta $d011

                lda #<irq_bitmap
                ldx #>irq_bitmap
                sta $314
                stx $315

                cli
_write_message:
                ldx #0
!:
                lda msg,x
                beq _loop
                sta $400+40*SCR_ROW,x   // draw message to screen
                txa
                and #%00000111
                tay
                lda cols,y
                sta $d800+40*SCR_ROW,x  // and colors
                inx
                jmp !-
_loop:
                lda #0 // hide the edges (lol, hides a bug)
                sta $d800+40*SCR_ROW
                sta $d800+40*(SCR_ROW+1)-1

                jmp *

irq_bitmap:
                // reset raster for textmode
                lda #$87
                sta $d012
                lda #<irq_text_mode
                ldx #>irq_text_mode
                sta $314
                stx $315

                lda #%00111000
                sta $d011
                lda #%00111000
                sta $d018
                lda #%11011000
                sta $d016

                // irq done
                dec $d019
                pla
                tay
                pla
                tax
                pla

                rti

irq_text_mode:
                lda $d012
                cmp #$85
                bmi irq_text_mode

                // text mode
                lda #%00011000
                sta $d011
                lda #%00010101
                sta $d018
                lda #%11001000
                sta $d016

                // Move fine scroll
                dec xoffi
                bpl !+
                ldx #7
                stx xoffi
                // We fine scrolled for 8 pixels,
                // so move all characters 1 pos to the left

                // copy first character to last column (so the message loops)
                lda $400+40*SCR_ROW
                sta $3ff+40*(SCR_ROW+1)

                ldy #0
                // copy all characters 1 to the left
!b:
                lda $401+40*SCR_ROW,y
                sta $400+40*SCR_ROW,y
                iny
                cpy #39 // 39 character for the row
                bne !b-

!:
                // update fine scroll register
                lda $D016
                and #%11111000
                ora xoffi
                sta $D016

                lda #$0 // reset irq for bitmap
                sta $d012
                lda #<irq_bitmap
                ldx #>irq_bitmap
                sta $314
            stx $315

            jsr music.play

                // irq done
                dec $d019
                pla
                tay
                pla
                tax
                pla

                rti

msg:
                .text " mr speaker rulez, scrollin' like 1984."
                .byte 0
xoffi:          .byte 7
cols:           .byte 11,12,15,3,3,15,12,11
spr:            .fill 64, $aa

 * = $0c00 "ScreenRam1"; screenRam1: .fill picture1.getScreenRamSize(), picture1.getScreenRam(i)
 * = $1c00 "ColorRam1"; colorRam1: .fill picture1.getColorRamSize(), picture1.getColorRam(i)
 * = $2000 "Bitmap1"; bitMap1: .fill picture1.getBitmapSize(), picture1.getBitmap(i)
 * = music.location "Music"; .fill music.size, music.getData(i)
