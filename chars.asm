            BasicUpstart2(main)
            *=$810
main:
                jsr init
                jsr setCharMem
_loop:
                jsr cycleColors
                jsr randoPrint
                jmp _loop

            // === init ===
init:
                lda #$0
                sta $d021
                sta $d020
                rts

            // === Set Char Memory ===
setCharMem:
                lda $d018
                and #%11110001
                ora #%00001000
                sta $d018               // locate chars at $2000

                lda #<$2000
                sta $fb
                lda #>$2000
                sta $fb+1
                ldy #$00
_copyFF:
                lda ch,y
                sta ($fb),y
                iny
                bne _copyFF

                inc $fb+1

_copyFF2:
                lda ch2,y
                sta ($fb),y
                iny
                bne _copyFF2

                rts

            // === Cycle Colors ===
cycleColors:
                lda #<$d800
                sta $fb
                lda #>$d800
                sta $fb+1

                ldx #$4
                ldy #$0
_colFF:
                tya
                adc coloff
                lsr
                lsr

                sta ($fb),y
                iny
                bne _colFF

                inc $fb+1
                dex
                bne _colFF

                dec coloff
                rts

randoPrint:
                //lda #$88 // lda has rotating num from cols!
                ldx #$07
                sta $fb
                stx $fb+1

                lda #<msg
                ldx #>msg
                sta $fd
                stx $fd+1

                jsr print
                rts

print:
                ldy #0
_pr:
                lda ($fd),y
                beq _pr_d
                sta ($fb),y
                iny
                jmp _pr
_pr_d:
                rts

            // ==== data ====
coloff:         .byte $0
msg:            .text " 1234567890! mr speaker! "
                .byte 0
ch:
  #import "ch1.asm"

ch2:
  #import "ch2.asm"
