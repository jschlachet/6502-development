;
; LCD 1602 in 4-bit mode and connected solely to PORT A
;
; Execellent notes:
; http://web.alfredstate.edu/faculty/weimandn/lcd/lcd_initialization/lcd_initialization_index.html

; zero page pointers to hold addresses for the target via device.
;

  .include "via.cfg"
  .include "lcd-4bit.cfg"

  .code ; .org $8000

  .include "via.s"
  .include "lcd-4bit.s"


reset:
  ldx #$ff              ; (2)
  txs                   ; (2)

  JSR set_via1

  ; initialize via port a
  LDX #0
  LDA #%01111111
  STA (ZP_VIA_DDRA,x)
  LDA $00
  STA (ZP_VIA_PORTA,x)

  ; left display  ; SINGLE PORT USE - PORT A
  JSR lcd_init

  LDA #%01111111        ; (2) all but top pin of A are output
  STA (ZP_VIA_DDRA,x)   ; (6) set direction register

  JSR delay_25ms
  JSR delay_25ms

  JMP print_hello


message_lcd: .asciiz "LCD 4bit mode!"

print_hello:
  jsr set_via1
  ldy #0
print_loop:
  lda message_lcd,y
  beq loop
  jsr print_char
  iny
  jmp print_loop

loop:
  JMP loop




nmi:
irq:
  jmp irq

  .segment "VECTORS" ; .org $fffa
  .word nmi
  .word reset
  .word irq
