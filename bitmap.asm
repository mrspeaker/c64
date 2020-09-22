.var picture1 = LoadBinary("mrspeaker.kla", BF_KOALA)

            BasicUpstart2(entry)

entry:
                lda #0
                sta $d020
                sta $d021

                lda #%00111011
                sta $d011
                lda #%00111000
                sta $d018
                lda #%11011000
                sta $d016

                jmp *

 * = $0c00 "ScreenRam_1"; screenRam_1: .fill picture1.getScreenRamSize(), picture1.getScreenRam(i)
 * = $1c00 "ColorRam_1"; colorRam_1: .fill picture1.getColorRamSize(), picture1.getColorRam(i)
 * = $2000 "Bitmap_1"; bitMap_1: .fill picture1.getBitmapSize(), picture1.getBitmap(i)
