;

.setcpu "65C02"

ZP_MESSAGE   = $08 ; message to send via serial

  .include "acia.cfg"
  .include "lcd-4bit.cfg"
  .include "via.cfg"


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
  BEQ key_escape
  CMP #$7f              ; backspace
  BEQ key_backspace
  ; CMP #$0d             ; enter
  ; BEQ key_enter
  CMP #$60              ; backtick
  BEQ key_backtick
  CMP #$03              ; Control-C
  BEQ perform_reset

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

perform_reset:
  JMP reset

key_escape:             ; $f0
  LDA #%00000001        ; Clear display
  JSR lcd_instruction
  LDA ACIA_WR_PTR       ; load write pointer
  STA ACIA_RD_PTR       ; store to read pointer (empty buffer)
  LDA #$0d              ; ASCII CR
  STA ACIA_DATA
  JSR delay_6551
  LDA #$0a              ; ASCII LF
  STA ACIA_DATA
  JSR delay_6551
  JMP irq_reset_end
key_backspace:          ; $7f
  LDA #%00010000        ; move cursor left
  JSR lcd_instruction
  LDA #$20              ; print space
  JSR print_char
  LDA #%00010000        ; move cursor left
  JSR lcd_instruction
  LDA ACIA_WR_PTR       ; load write pointer
  DEC                   ; decrement by one
  STA ACIA_WR_PTR       ; save pointer back out
  JSR send_backspace_serial
  jmp irq_reset_end
key_backtick:
  LDA #%00000001        ; Clear display
  JSR lcd_instruction
  JSR print_buffer
  JMP irq_reset_end

send_backspace_serial:
  LDA #$08              ; ASCII BS
  STA ACIA_DATA
  JSR delay_6551
  LDA #$20              ; ASCII space
  STA ACIA_DATA
  JSR delay_6551
  LDA #$08              ; ASCII BS
  STA ACIA_DATA
  JSR delay_6551
  RTS

print_buffer_contents:
  PHA
  PLA
  RTS

print_buffer:
  PHA
  PHX

  JSR acia_buffer_diff
  BEQ print_buffer_empty

  JSR set_message_buffer
  JSR send_message
  ;
read_acia_buffer_loop:
  JSR read_acia_buffer        ; read char from buffer
  STA ACIA_DATA              ; output to serial console
  JSR delay_6551
  ; move read pointers
  INC ACIA_RD_PTR
  ;
  JSR acia_buffer_diff        ; check pointer different
  BEQ read_acia_buffer_end    ; if buffer empty then exit
  JSR read_acia_buffer_loop
read_acia_buffer_end:
  ;
  JSR set_message_crlf
  JSR send_message
  JMP print_buffer_end
  ;
print_buffer_empty:
  JSR set_message_empty
  JSR send_message
  JMP print_buffer_end
  ;
print_buffer_end:
  PLX
  PLA
  RTS



  .segment "VECTORS"
  .word nmi
  .word reset
  .word irq
