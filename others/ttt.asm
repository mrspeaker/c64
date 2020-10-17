        BasicUpstart2(entry)

       // * = $0801
        .const CANVAS_START_Y = $60
        .const canvasEnd = $70
entry:
           lda #$00
           sta $d020
           sta $d021
/*
           tax

clrscreen:
           sta $0400,x
           sta $0500,x
           sta $0600,x
           sta $0700,x
           sta $2000,x
           dex
           bne clrscreen

           lda #$18
           sta $d018

mainloop:
           lda $d012
           cmp #$ff
           bne mainloop

           ldx counter
           inx
           cpx #$28
           bne juststx
           ldx #$00
juststx:
           stx counter

           lda $2000,x
           eor #$ff
           sta $2000,x

           jmp mainloop

counter:
           .byte 8
 */

NextFrame:

    ldy #CANVAS_START_Y-1                   // rasterbar to start drawing canvas on
    ldx #$00                                // canvas line index

    cpy $d012                               // are we on y raster line?
    bne *-3                                 // if not yet, loop until we are
    iny                                     // set raster line we need to draw on next

!loop:
    lda canvas,x                            // load color for next raster line from canvas' current line index
    cpy $d012                               // are we on y raster line?
    bne *-3                                 // if not yet, loop until we are
    sta $d021                               // just landed on next raster line, set background color from canvas

    cpx #canvasEnd-canvas                   // have we drawn every line from canvas?
    beq CalcNextFrame
    iny                                     // move onto next raster line
    inx                                     // move onto next canvas line
    jmp !loop-                              // draw next raster line

CalcNextFrame:
    // calculate new canvas
    jmp NextFrame


    .align $100
canvas:
	.byte $02,$0c,$0f,$01,$0f,$0c,$0b,$02
	.byte $09,$0c,$0f,$01,$0f,$0c,$0b,$09
	.byte $07,$0c,$0f,$01,$0f,$0c,$0b,$07
	.byte $05,$0c,$0f,$01,$0f,$0c,$0b,$05
	.byte $06,$0c,$0f,$01,$0f,$0c,$0b,$06
	.byte $04,$0c,$0f,$01,$0f,$0c,$0b,$04
	.byte $02,$0c,$0f,$01,$0f,$0c,$0b,$02
	.byte $09,$0c,$0f,$01,$0f,$0c,$0b,$09
	.byte $07,$0c,$0f,$01,$0f,$0c,$0b,$07
	.byte $05,$0c,$0f,$01,$0f,$0c,$0b,$05
	.byte $06,$0c,$0f,$01,$0f,$0c,$0b,$06
	.byte $04,$0c,$0f,$01,$0f,$0c,$0b,$04
	.byte $05,$0c,$0f,$01,$0f,$0c,$0b,$05
	.byte $06,$0c,$0f,$01,$0f,$0c,$0b,$06
	.byte $04,$0c,$0f,$01,$0f,$0c,$0b,$04
	.byte $02,$0c,$0f,$01,$0f,$0c,$0b,$02
	.byte $02,$0c,$0f,$01,$0f,$0c,$0b,$02
	.byte $09,$0c,$0f,$01,$0f,$0c,$0b,$09
	.byte $07,$0c,$0f,$01,$0f,$0c,$0b,$07
	.byte $05,$0c,$0f,$01,$0f,$0c,$0b,$05
	.byte $06,$0c,$0f,$01,$0f,$0c,$0b,$06
	.byte $04,$0c,$0f,$01,$0f,$0c,$0b,$04
	.byte $02,$0c,$0f,$01,$0f,$0c,$0b,$02
	.byte $09,$0c,$0f,$01,$0f,$0c,$0b,$09
	.byte $07,$0c,$0f,$01,$0f,$0c,$0b,$07
	.byte $05,$0c,$0f,$01,$0f,$0c,$0b,$05
	.byte $06,$0c,$0f,$01,$0f,$0c,$0b,$06
	.byte $04,$0c,$0f,$01,$0f,$0c,$0b,$04
	.byte $05,$0c,$0f,$01,$0f,$0c,$0b,$05
	.byte $06,$0c,$0f,$01,$0f,$0c,$0b,$06
	.byte $04,$0c,$0f,$01,$0f,$0c,$0b,$04
	.byte $02,$0c,$0f,$01,$0f,$0c,$0b,$02
