.ifndef _COMMAND_S_
_COMMAND_S_ = 1

;
COMMAND_HELP:     .asciiz "help"
COMMAND_VERSION:  .asciiz "version"
COMMAND_LED:      .asciiz "led"
COMMAND_STATUS:   .asciiz "status"

NULL    = $00
EQUAL   = $00
LT      = $ff
GT      = $01


  .include "zeropage.cfg"

; ref: http://prosepoetrycode.potterpcs.net/tag/6502/
; Arguments:
; $F0-$F1: First string
; $F2-$F3: Second string
; Returns A with comparison result:
; -1: First string is less than second
; 0: Strings are equal
; 1; First string is greater than second
strcmp:
  PHY
  LDY #$00
strcmp_load:
  LDA (ZP_COMMAND), Y ; command we're comparing with 
  CMP (ZP_INPUT), Y   ; user input
  BNE strcmp_lesser
  INY
  CMP #NULL
  BNE strcmp_load
  LDA #EQUAL
  JMP strcmp_done
strcmp_lesser:
  BCS strcmp_greater
  LDA #LT
  JMP strcmp_done
strcmp_greater:
  LDA #GT
  JMP strcmp_done
strcmp_done:
  PLY
  RTS

check_command:

parse_command:
  PHA
  PHX
  PHY
 
  ; help
  LDA #<COMMAND_HELP
  STA ZP_COMMAND
  LDA #>COMMAND_HELP
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BEQ parse_command_help
  
  ; version
  LDA #<COMMAND_VERSION
  STA ZP_COMMAND
  LDA #>COMMAND_VERSION
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BEQ parse_command_version

  ; led
  LDA #<COMMAND_LED
  STA ZP_COMMAND
  LDA #>COMMAND_LED
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BEQ parse_command_led

  ; led
  LDA #<COMMAND_STATUS
  STA ZP_COMMAND
  LDA #>COMMAND_STATUS
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BEQ parse_command_status

  ; default - unknown
  LDA #<message_unknown
  STA ZP_MESSAGE
  LDA #>message_unknown
  STA ZP_MESSAGE+1
  JSR send_message_serial
  JMP option_done

parse_command_help:
  LDA #<message_help
  STA ZP_MESSAGE
  LDA #>message_help
  STA ZP_MESSAGE+1
  JSR send_message_serial
  JMP option_done


; assuming via2 is active (left via)
parse_command_led:      ; toggle via 2, port b, pin 7 
  LDX #0

  LDA (ZP_VIA_DDRB,x)   ; read ddr for port b and save on stack
  PHA
  ORA #%10000000        ; set pin 7 to 1 
  STA (ZP_VIA_DDRB,x)   ; 

  LDA (ZP_VIA_PORTB,x)
  EOR #%10000000        ; reverse bit 7
  STA (ZP_VIA_PORTB,x)

  PLA                   ; restore ddr and send
  STA (ZP_VIA_DDRB,x)

  LDA #<message_led     ; send toggle message
  STA ZP_MESSAGE
  LDA #>message_led
  STA ZP_MESSAGE+1
  JSR send_message_serial
  ;
  JMP option_done


parse_command_version:
  LDA #<message_version
  STA ZP_MESSAGE
  LDA #>message_version
  STA ZP_MESSAGE+1
  JSR send_message_serial
  JMP option_done

parse_command_status:
  ; assuming led pin is in output mode
  LDA #<message_status
  STA ZP_MESSAGE
  LDA #>message_status
  STA ZP_MESSAGE+1
  JSR send_message_serial
  LDX #0
  LDA (ZP_VIA_PORTB,x)
  CMP #%10000000        ; test led pin
  BCC status_led_off    ; branch if bit 7 was 0 (overflow from AND)
status_led_on:
  LDA #<message_led_on
  STA ZP_MESSAGE
  LDA #>message_led_on
  STA ZP_MESSAGE+1
  JMP status_led_done
status_led_off:
  LDA #<message_led_off
  STA ZP_MESSAGE
  LDA #>message_led_off
  STA ZP_MESSAGE+1
status_led_done:
  JSR send_message_serial
  JMP option_done

option_done:
  PLY
  PLX
  PLA
  RTS


; reminder -- 
; ORA #%01000000 - set bit 6 to 1
; AND #%10111111 - set bit 6 to 0
; EOR #%01000000 - reverse bit 6
; AND #%01000000 - if bit 6 is 0, then set overflow flag



.endif