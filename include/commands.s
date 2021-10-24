.ifndef _COMMAND_S_
_COMMAND_S_ = 1

;
COMMAND_HELP:     .asciiz "help"
COMMAND_VERSION:  .asciiz "version"
COMMAND_LED:      .asciiz "led"
COMMAND_STATUS:   .asciiz "status"
COMMAND_BEEP:     .asciiz "beep"
COMMAND_CRASH:    .asciiz "crash"
COMMAND_READ:     .asciiz "read"
COMMAND_WRITE:    .asciiz "write"

NULL    = $00
EQUAL   = $00
LT      = $ff
GT      = $01


  .include "zeropage.cfg"

  .include "sn76489.s"

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
  BNE parse_command_help_continue
  JMP parse_command_help
parse_command_help_continue:
  
  ; version
  LDA #<COMMAND_VERSION
  STA ZP_COMMAND
  LDA #>COMMAND_VERSION
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_version_continue
  JMP parse_command_version
parse_command_version_continue:

  ; led
  LDA #<COMMAND_LED
  STA ZP_COMMAND
  LDA #>COMMAND_LED
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_led_continue
  JMP parse_command_led
parse_command_led_continue:

  ; status
  LDA #<COMMAND_STATUS
  STA ZP_COMMAND
  LDA #>COMMAND_STATUS
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_status_continue
  JMP parse_command_status
parse_command_status_continue:

  ; beep
  LDA #<COMMAND_BEEP
  STA ZP_COMMAND
  LDA #>COMMAND_BEEP
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_beep_continue
  JMP parse_command_beep
parse_command_beep_continue:

  ;. beep
  LDA #<COMMAND_CRASH
  STA ZP_COMMAND
  LDA #>COMMAND_CRASH
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_crash_continue
  JMP parse_command_crash
parse_command_crash_continue:

  ; read
  LDA #<COMMAND_READ
  STA ZP_COMMAND
  LDA #>COMMAND_READ
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_read_continue
  JMP parse_command_read
parse_command_read_continue:

  ; write
  LDA #<COMMAND_WRITE
  STA ZP_COMMAND
  LDA #>COMMAND_WRITE
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_write_continue
  JMP parse_command_write
parse_command_write_continue:
  
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


parse_command_beep:
  JSR beep
  JMP option_done

parse_command_crash:
  JSR sound_crash
  JMP option_done

parse_command_version:
  LDA #<message_version
  STA ZP_MESSAGE
  LDA #>message_version
  STA ZP_MESSAGE+1
  JSR send_message_serial
  JMP option_done

; assuming via2 is active (left via)
parse_command_led:      ; toggle via 2, port b, pin 7 
  LDX #0

  LDA (ZP_VIA_DDRA,x)   ; read ddr for port b and save on stack
  PHA
  ORA #%10000000        ; set pin 7 to 1  (output)
  STA (ZP_VIA_DDRA,x)   ; 

  LDA (ZP_VIA_PORTA,x)
  EOR #%10000000        ; reverse bit 7
  STA (ZP_VIA_PORTA,x)
  AND #%10000000        ; set other bits to 0
  STA LED_STATUS        ; ensure led_status is always only ever bit 7

  PLA                   ; restore ddr and send
  STA (ZP_VIA_DDRA,x)

  LDA #<message_led     ; send toggle message
  STA ZP_MESSAGE
  LDA #>message_led
  STA ZP_MESSAGE+1
  JSR send_message_serial
  ;
  JMP option_done



parse_command_status:
  ; assuming led pin is in output mode
  LDA #<message_status
  STA ZP_MESSAGE
  LDA #>message_status
  STA ZP_MESSAGE+1
  JSR send_message_serial
  BIT LED_STATUS
  BMI status_led_on
status_led_off:
  LDA #<message_led_off
  STA ZP_MESSAGE
  LDA #>message_led_off
  STA ZP_MESSAGE+1
  JMP status_led_done
status_led_on:
  LDA #<message_led_on
  STA ZP_MESSAGE
  LDA #>message_led_on
  STA ZP_MESSAGE+1
status_led_done:
  JSR send_message_serial
  JMP option_done

parse_command_read:
parse_command_write:
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