  BasicUpstart2(entry)

entry:
  sei
lp:     ldy #$44
    cpy $d012
    bne *-3
    ldx #0
!:   lda colors,x
    cpy $d012
    bne *-3
    sta $d020
    iny
    inx
    bpl !-
  jmp lp


colors:
    .byte 11,0,11,0,11,0,11,0
    .byte 11,0,11,0,11,0,11,0
    .byte 11,0,11,0,11,0,11,0
    .byte 11,0,11,0,11,0,11,0
    .byte 11,0,11,0,11,0,11,0
    .byte 11,0,11,0,11,0,11,0
    .byte 11,0,11,0,11,0,11,0
    .byte 11,0,11,0,11,0,11,0
    .byte 11,0,11,0,11,0,11,0
    .byte 11,0,11,0,11,0,11,0
    .byte 11,0,11,0,11,0,11,0
    .byte 11,0,11,0,11,0,11,0
    .byte 11,0,11,0,11,0,11,0
    .byte 11,0,11,0,11,0,11,0
    .byte 11,0,11,0,11,0,11,0
  .byte 11,0,11,0,11,0,11,0