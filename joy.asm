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
                lda #$0
                sta $d020
                sta $d021

                jsr init_sprites
                rts

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

                lda #180
                sta $d002
                sta $d003

                rts

update:
                lda player_x
                ldx player_y

                clc
                adc player_dir
                bcc !+
                // why does this work without resseting?
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

                lda $d01e
                and #%00000001
                beq !+
                dec $d020
                lda $dc04
                eor $dc05
                sta $d003
!:

                rts

player_x:       .byte 80
player_y:       .byte 60
player_dir:     .byte 1
spr_bg:
                .fill 64, $aa
