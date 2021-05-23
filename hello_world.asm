; Import definitions file
INCLUDE "gbhw.inc"

; Define constants to work with a sprite
_SPR0_Y   EQU _OAMRAM
_SPR0_X   EQU _OAMRAM + 1
_SPR0_NUM EQU _OAMRAM + 2
_SPR0_ATT EQU _OAMRAM + 3

; Variables to know where to move the sprite
_MOVX EQU _RAM
_MOVY EQU _RAM + 1

; Program start
SECTION "start", ROM0[$0100]
  NOP
  JP start

  ; Header
  ROM_HEADER ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE

; start label
start:
  NOP
  DI
  LD SP, $FFFF

; initialization label
initialization:
  ; Set palette
  LD A, %11100100
  LD [rBGP], A
  LD [rOBP0], A

  ; Set scrolls (X and Y) to (0,0)
  LD A, 0
  LD [rSCX], A
  LD [rSCY], A

  CALL turn_off_LCD

  ; Load tile in the tile memory
  LD HL, tiles
  LD DE, _VRAM
  LD B, 32 ; bytes to be copied, 2 tiles

.loop_load_tile
  LD A, [HL]
  LD [DE], A
  DEC B
  JR Z, .end_loop_load_tile
  INC HL
  INC DE
  JR .loop_load_tile
.end_loop_load_tile

  ; Write tiles
  LD HL, _SCRN0
  LD DE, 32*32 ; amount of bytes in the background map

; Clean screen (using a background tile)
.loop_clean_screen
  LD A, 0
  LD [HL], A
  DEC DE
  LD A, D
  OR E
  JP Z, .end_loop_clean_screen
  INC HL
  JP .loop_clean_screen
.end_loop_clean_screen

  ; Load sprite
  LD A, 30
  LD [_SPR0_Y], A ; Sprite's Y position
  LD A, 30
  LD [_SPR0_X], A ; Sprite's X position
  LD A, 1
  LD [_SPR0_NUM], A ; Tile number in the tile table
  LD A, 0
  LD [_SPR0_ATT], A ; Special attributes (nothing for now)

; Config and activate display
LD A, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON
LD [rLCDC], A

; Set animation variables
LD A, 1
LD [_MOVX], A
LD [_MOVY], A

; Animation (game loop start)
animation:
  ; Wait for V-Blank
.wait:
  LD A, [rLY]
  CP 145
  JR NZ, .wait

  ; Y movement
  LD A, [_SPR0_Y]
  LD HL, _MOVY
  ADD A, [HL]
  LD HL, _SPR0_Y
  LD [HL], A

  ; Compare to see if we need to change the direction
  CP 152        ; Max Y
  JR Z, .dec_y
  cp 16         ; Min Y
  JR Z, .inc_y
  JR .end_y     ; No change needed

.dec_y:
  LD A, -1
  LD [_MOVY], A
  JR .end_y

.inc_y:
  LD A, 1
  LD [_MOVY], A

.end_y:
  ; X movement
  LD A, [_SPR0_X]
  LD HL, _MOVX
  ADD A, [HL]
  LD HL, _SPR0_X
  LD [HL], A

  ; Compare to see if we need to change the direction
  CP 160    ; Max X
  JR Z, .dec_x
  CP 8      ; Min X
  JR Z, .inc_x
  JR .end_x ; No changes needed

.dec_x:
  LD A, -1
  LD [_MOVX], A
  JR .end_x

.inc_x:
  LD A, 1
  LD [_MOVX], A

.end_x:
  CALL delay
  JR animation
; Game loop end

; LCD's turn off rutine
turn_off_LCD:
  LD A, [rLCDC]
  RLCA
  RET NC ; do nothing if the screen is already turned off

; Wait for V-Blank
.wait_VBlank
  LD A, [rLY]
  CP 145
  JR NZ, .wait_VBlank

  ; Here we're in V-Blank, turn of the display
  LD A, [rLCDC]
  RES 7, A
  LD [rLCDC], A

  RET

delay:
  LD DE, 2000 ; How many times the loop will be executed

.start_delay:
  DEC DE
  LD A, D
  OR E
  JR Z, .end_delay
  NOP
  JR .start_delay
.end_delay
  RET

; Tile data
tiles:
  ; Background tile
  DB  $AA, $00, $44, $00, $AA, $00, $11, $00
  DB  $AA, $00, $44, $00, $AA, $00, $11, $00
  ; Our tile to display
  DB $30, $30, $30, $20, $05, $7C, $80, $B0
  DB $30, $30, $00, $30, $40, $50, $10, $10
end_tiles:
