; Import definitions file
INCLUDE "gbhw.inc"

; Define constants to work with a sprite
_SPR0_Y   EQU _OAMRAM
_SPR0_X   EQU _OAMRAM + 1
_SPR0_NUM EQU _OAMRAM + 2
_SPR0_ATT EQU _OAMRAM + 3

; Variable to save the joypad state
_PAD EQU _RAM

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

  ; Second palette
  LD A, %00011011
  LD [rOBP1], A

  ; Set scrolls (X and Y) to (0,0)
  LD A, 0
  LD [rSCX], A
  LD [rSCY], A

  CALL turn_off_LCD

  ; Load tile in the tile memory
  LD HL, tiles
  LD DE, _VRAM
  LD B, 32 ; bytes to be copied, 2 tiles

.loop_load_tile:
  LD A, [HL]
  LD [DE], A
  DEC B
  JR Z, .end_loop_load_tile
  INC HL
  INC DE
  JR .loop_load_tile
.end_loop_load_tile

; Write tiles
; Fill background with corresponding tile
  LD HL, _SCRN0
  LD DE, 32*32 ; amount of bytes in the background map

; Clean screen (using a background tile)
.loop_clean_background
  LD A, 0
  LD [HL], A
  DEC DE
  LD A, D
  OR E
  JP Z, .end_loop_clean_background
  INC HL
  JP .loop_clean_background
.end_loop_clean_background

; Clean memory from sprites
  LD HL, _OAMRAM
  LD DE, 40*4 ; 40 sprites x 4 bytes each one

.loop_clean_sprites
  LD A, 0
  LD [HL], A
  DEC DE
  LD A, D
  OR E
  JP Z, .end_loop_clean_sprites
  INC HL
  JP .loop_clean_sprites
.end_loop_clean_sprites

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

; Read joypad (game loop start)
movement:
  ; Read joypad
  CALL read_joypad

  ; Wait for V-Blank
.wait:
  LD A, [rLY]
  CP 145
  JR NZ, .wait

  ; Move sprite depending on the pressed button
  ; Check right
  LD A, [_PAD]
  AND %00010000
  CALL NZ, move_right

  ; Check left
  LD A, [_PAD]
  AND %00100000
  CALL NZ, move_left

  ; Check up
  LD A, [_PAD]
  AND %01000000
  CALL NZ, move_up

  ; Check down
  LD A, [_PAD]
  AND %10000000
  CALL NZ, move_down

  ; Change palette color if A is pressed
  ; Check A
  LD A, [_PAD]
  AND %00000001
  CALL NZ, change_palette

  ; Delay
  CALL delay
  JR movement
; Game loop end

; Movement routines
move_right:
  LD A, [_SPR0_X]
  CP 160
  RET Z

  INC A
  LD [_SPR0_X], A
  RET

move_left:
  LD A, [_SPR0_X]
  CP 8
  RET Z

  DEC A
  LD [_SPR0_X], A
  RET

move_up:
  LD A, [_SPR0_Y]
  CP 16
  RET Z

  DEC A
  LD [_SPR0_Y], A
  RET

move_down:
  LD A, [_SPR0_Y]
  CP 152
  RET Z

  INC A
  LD [_SPR0_Y], A
  RET

; Change palette routine
change_palette:
  LD A, [_SPR0_ATT]
  AND %00010000
  JR Z, .palette_0

  LD A, [_SPR0_ATT]
  RES 4, A
  LD [_SPR0_ATT], A

  CALL delay
  RET

.palette_0:
  LD A, [_SPR0_ATT]
  SET 4, A
  LD [_SPR0_ATT], A

  RET

; Joypad reading routine
read_joypad:
  ; Read d-pad
  LD A, %00100000
  LD [rP1], A

  ; Read value several times to avoid bouncing effect
  LD A, [rP1]
  LD A, [rP1]
  LD A, [rP1]
  LD A, [rP1]

  AND $0F
  SWAP A
  LD B, A

  ; Read buttons
  LD A, %00010000
  LD [rP1], A

  ; Read value several times to avoid bouncing effect
  LD A, [rP1]
  LD A, [rP1]
  LD A, [rP1]
  LD A, [rP1]

  AND $0F
  OR B
  CPL
  LD [_PAD], A
  RET

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
