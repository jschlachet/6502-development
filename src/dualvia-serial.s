;

  .setcpu "65C02"


  .include "acia.cfg"
  .include "lcd-4bit.cfg"
  .include "via.cfg"

ZP_MESSAGE   = $08 ; message to send via serial

message_startup: .byte $0d, $0a, "Starting up.", $0d, $0a, $00 ; CR LF NULL
message_empty: .byte "Buffer empty.", $0d, $0a, $00
message_buffer: .byte $0d, $0a, "Buffer contents:", $0d, $0a, $00
message_crlf: .byte $0d, $0a, $00

  .code

  .include "acia.s"
  .include "lcd-4bit.s"
  .include "via.s"

reset:
  ldx #$ff
  txs

  ldx #0

  jsr set_via2
  jsr lcd_init

  ; make a dollar size prompt on lcd
  lda #$24 ; dollar sign
  jsr print_char

  jsr init_acia

  jsr set_message_startup
  jsr send_message

  cli                   ; clear interrupt (enable)
  jsr loop


loop:
  jmp loop

nmi:
  rti

irq:
  PHA
  PHX
  LDA ACIA_STATUS
  AND #$08 ; check for rx byte available
  BEQ irq_end

  LDA ACIA_DATA

  CMP #$1b              ; escape
  BNE key_escape_continue
  JMP key_escape
key_escape_continue:

  CMP #$7f              ; backspace
  BNE key_backspace_continue
  JMP key_backspace
key_backspace_continue:
  
  ; CMP #$0d             ; enter
  ; BEQ key_enter

  CMP #$60              ; backtick
  BNE key_backtick_continue
  JMP key_backtick
key_backtick_continue:
 
  CMP #$03              ; Control-C
  BNE perform_reset_continue
  JMP perform_reset
perform_reset_continue:

  ; all other keys, ...
  JSR write_acia_buffer
  JSR print_char

  ; echo back
  STA ACIA_DATA
  JSR delay_6551

  ; check how much data is in Buffer
  JSR acia_buffer_diff
  CMP #$f0
  BCC irq_end

  ; ; less than 0x0f (15) chars left, push rts down
  LDA #$01
  STA ACIA_COMMAND

  ;sta ACIA_DATA
  ; debugging; this sends a char to the lcd.
  ; it sends the same char indefinitely.
  ; lda #$41 ; "A"
  ; jsr print_char
irq_reset_end:
  BIT ACIA_STATUS ; reset interrupt of ACIA
irq_end:
  PLX
  PLA
  RTI



  .segment "VECTORS"
  .word nmi
  .word reset
  .word irq
