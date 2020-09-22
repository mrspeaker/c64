            BasicUpstart2(entry)

entry:
                jsr init
loop:
                lda #0
!:
                cmp $d012
                bne !-
                jsr update
                jmp loop

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

                lda #%11110100
                sta $d01a
                sta $d019

                lda #<irq
                ldx #>irq
                sta $314
                stx $315

                cli

                rts
irq:
                dec $d020

                lda $d01e
                and #%00000001
                beq !+

                lda $dc04
                eor $dc05
                sta $d003
!:
                asl $d019
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

                ldx #64
!:
                lda spr_bg,x
                sta $340,x
                dex
                bpl !-

                lda #$340/64
                sta $7f8
                sta $7f9

                lda #70
                sta $d002
                sta $d003
                lda #20
                sta $d000

                rts

update:
                lda player_x
                ldx player_y

                clc
                adc player_dir
                bcc !+
                tax
                lda $d010
                eor #$1
                sta $d010
                txa
!:
                sta player_x
                sta $d000
                stx $d001

                lda $dc00
                lsr
                bcs !+
                dec player_y
!:
                lsr
                bcs !+
                inc player_y
!:

                rts

player_x:       .byte 20
player_y:       .byte 60
player_dir:     .byte 1
spr_bg:
                .fill 64, [$aa, $55]
