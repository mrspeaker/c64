  // https://github.com/smnjameson/LetsMakeAC64Game/blob/master/src/maps/mapdata.asm
  // https://github.com/smnjameson/LetsMakeAC64Game/blob/master/src/maps/maploader.asm#L153

LEVELS: {

  // Template
  MAP: {
    par: .byte 10
    peeps: {
      p_x_lo:.byte 0, 0, 0, 0, 0
      p_x_hi:.byte $2e, $75, $20, 0, 0
      p_y_lo:.byte $00, $00, $00, 0, 0
      p_y_hi:.byte $62, $22, $42, 0, 0
      p_x_min:.byte $2d, $2d, $11, 0, 0
      p_x_max:.byte $47, $7f, $27, 0, 0
      p_sp:.byte 25, 30, -20, 0, 0
    }
  }


lookup:
  .word Level_001
  .word Level_002

  Level_001: {
    par: .byte 10
    peeps: {
      p_x_lo:.byte 0, 0, 0, 0, 0
      p_x_hi:.byte $2e, 0, 0, 0, 0
      p_y_lo:.byte 0, 0, 0, 0, 0
      p_y_hi:.byte $62, 0, 0, 0, 0
      p_x_min:.byte $2d, 0, 0, 0, 0
      p_x_max:.byte $47, 0, 0, 0, 0
      p_sp:.byte 25, 0, 0, 0, 0
    }
  }

  Level_002: {
    par: .byte 20
    peeps: {
      p_x_lo:.byte 0, 0, 0, 0, 0
      p_x_hi:.byte $2e, $75, $20, 0, 0
      p_y_lo:.byte $00, $00, $00, 0, 0
      p_y_hi:.byte $62, $22, $42, 0, 0
      p_x_min:.byte $2d, $2d, $11, 0, 0
      p_x_max:.byte $47, $7f, $27, 0, 0
      p_sp:.byte 25, 30, -20, 0, 0
    }
  }
}
