/*
   Test reading joystick values.
   Test sprite collision ($D01e)
 */

            BasicUpstart2(entry)

entry:
                jsr init
                jmp *

init:
                sei
                lda #$0
                sta $d020
                sta $d021

                jsr init_sprites

                lda #%01111111
                sta $dc0d               // Turn off CIAs Timer interrupts
                sta $dd0d
                lda $dc0d               // cancel all CIA-IRQs in queue/unprocessed
                lda $dd0d

                lda #%00000001 // enable raster
                sta $d01a
                sta $d019

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

                jsr $E544 //cls
                rts

irq:
                lda $d019
                ora #%00000001
                sta $d019

                nop
                nop
                nop

                lda score
                sta $d020

                jsr update

                // Check collision
                lda $d01e
                and #%00000001
                beq !+

                jsr hit
!:
                cmp (0,x)
                lda #0
                sta $d020
                pla
                tay
                pla
                tax
                pla
                rti

init_sprites:
                lda #%00000011
                sta $d015

                lda #$1

                ldx #64*2
!:
                lda spr_bg,x
                sta $340,x
                dex
                bpl !-

                lda #$340/64
                sta $7f8
                lda #$340/64+1
                sta $7f9

                lda #$a0
                sta $d002
                sta $d003
                lda #$f0
                sta $d000

                lda #1
                sta $d028

                rts

update:
                inc $d003

                lda player_x
                ldx player_y

                clc
                adc player_dir
                tay
                bcc noMSB
                // Set MSB
                lda $d010
                eor #$1
                sta $d010
noMSB:
                lda $d010
                lsr
                bcc noWrap

                tya
                cmp #80
                bmi noWrap
                lda $d010
                eor #$1
                sta $d010
                ldy #0
noWrap:
                tya
                sta player_x
                sta $d000
                stx $d001

                lda $dc00 // bits: 0=up,1=down,2=left,3=right,4=fire
                lsr       // if bit 0 was 0 (active low), it's rotated to carry
                bcs down  // so carry will be clear if pressed
                dec player_y
down:
                lsr
                bcs left
                inc player_y
left:
                lsr
                bcs right
right:
                lsr
                bcs fire
fire:
                lsr
                bcs !+
                jsr hit
!:
                rts

hit:
                 // Hit!
                //dec $d020
                inc score
                lda $dc04
                eor $dc05
                sta $d003
                rts


player_x:       .byte 20
player_y:       .byte 60
player_dir:     .byte 2
score:          .byte 1


spr_bg:
spr1:           .byte 0,127,0,1,255,192,3,255,224,3,231,224
	            .byte 7,217,240,7,223,240,2,217,240,3,231,224
	            .byte 3,255,224,3,255,224,2,255,160,1,127,64
	            .byte 1,62,64,0,156,128,0,156,128,0,73,0,0,73,0,0
	            .byte 62,0,0,62,0,0,62,0,0,28,0,0

spr2:           .byte 12,0,192,12,0,192,3,3,0,3,3,0
                .byte 15,255,192,15,255,192
                .byte 60,252,240,60,252,240
                .byte 255,255,252,255,255,252
                .byte 207,255,204,207,255,204
                .byte 204,0,204,204,0,204
                .byte 3,207,0,3,207,0
                .byte 0,0,0,0,0,0,0,0,0,0,0,0
                .byte 0,0,0
