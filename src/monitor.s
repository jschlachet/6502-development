;
; right via (via1)
;  -- PA0..PA3 to LCD D4..D7
;  -- PA4      to LCD E
;  -- PA5      to LCD RW
;  -- PA6      to LCD RS
;  -- PA7      to LED
;  -- PB0..PB7 unconnected
; left via  (via2)
;  -- PA0..PA7 to ACIA D7..D0
;  -- PB0      to ACIA /WE
;  -- PB1      to ACIA RDY
;  -- PB2..PB7 unconnected

  .setcpu "65C02"


  .include "acia.cfg"
  .include "lcd-4bit.cfg"
  .include "via.cfg"
  .include "zeropage.cfg"



  .code

  .include "acia.s"
  .include "lcd-4bit.s"
  .include "via.s"
  .include "sn76489.s"

reset:
  ldx #$ff
  txs

  jsr init_via

  jsr sound_mute        ; TEMP

  jsr set_via2
  jsr lcd_init

  LDA #0
  STA LED_STATUS

  ; ; make prompt on lcd
  ; lda #$3e ; greater than sign
  ; jsr print_char

  ; initialize ZP_INPUT as pointer to user input string
  LDA #<INPUT_COMMAND
  STA ZP_INPUT
  LDA #>INPUT_COMMAND
  STA ZP_INPUT+1

  jsr init_acia

  jsr set_message_startup
  jsr send_message_serial

  jsr show_prompt
 
  cli                   ; clear interrupt (enable)
  jsr loop

init_via:
  LDX #$0
  ; bring both ports of via to a known initial state
  ;
  JSR set_via1          ; right
  ;
  LDA #%00000000
  STA (ZP_VIA_PORTA,x)
  LDA #%00000011        ; init pin 0 (/WE) as high (inactive)
  STA (ZP_VIA_PORTB,x)
  ; hard set both port a and b to output
  LDA #$ff
  STA (ZP_VIA_DDRA,x)
  LDA #%00000001 ; pin 0 is /WE (output so we can write it), 1 in RDY (input)
  STA (ZP_VIA_DDRB,x)
  ;
  JSR set_via2          ; left
  ;
  LDA #%11111111        ; all pins output
  STA (ZP_VIA_DDRA,x)
  STA (ZP_VIA_DDRB,x)
  LDA #%00000000        ; all pins low
  STA (ZP_VIA_PORTA,x)
  STA (ZP_VIA_PORTB,x)
  RTS

show_prompt:
  JSR set_message_crlf
  JSR send_message_serial
  JSR set_message_prompt
  JSR send_message_serial
  RTS

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
  
  CMP #$0d              ; enter
  BNE key_enter_continue
  JMP key_enter
key_enter_continue:

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

  ; special keys are done.
  ; default action is to echo back
  STA ACIA_DATA
  JSR delay_6551

  ; check how much data is in Buffer
  JSR acia_buffer_diff
  CMP #$f0
  BCC irq_end

  JSR set_message_bufferfull
  JSR send_message_serial
  ; ; less than 0x0f (15) chars left, push rts down
  LDA #$01
  STA ACIA_COMMAND
  ; TODO what else should we do here? maybe soft reset or clear buffer.

  ;sta ACIA_DATA
  ; debugging; this sends a char to the lcd.
  ; it sends the same char indefinitely.
  ; lda #$41 ; "A"
  ; jsr print_char
  JMP irq_reset_end
irq_reset_end_prompt:
  JSR show_prompt
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
