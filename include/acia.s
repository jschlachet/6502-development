;
;
;


init_acia:
  PHA
  LDA #$00
  STA ACIA_STATUS
  LDA #%00001001        ; $09 - No parity, no echo, interrupt enabled
  STA ACIA_COMMAND
  LDA #%00011111        ; $1f - 1 stop bit, 8 data bits, 19200 baud
  STA ACIA_CONTROL
  ; buffer setup
  STZ ACIA_RD_PTR       ; init read pointer
  STZ ACIA_WR_PTR       ; init write pointer
  PLA
  RTS


send_message:
  PHA
  PHY
  LDY #0
send_message_next:
  LDA (ZP_MESSAGE),y
  BEQ send_message_done
  STA ACIA_DATA
  JSR delay_6551
  INY
  jmp send_message_next
send_message_done:
  BIT ACIA_STATUS       ; TRY TO CLEAR STATUS
  PLY
  PLA
  RTS

set_message_empty:
  PHA
  LDA #<message_empty
  STA $08
  LDA #>message_empty
  STA $09
  PLA
  RTS
set_message_startup:
  pha
  LDA #<message_startup
  STA $08
  LDA #>message_startup
  STA $09
  PLA
  RTS
set_message_buffer:
  PHA
  LDA #<message_buffer
  STA $08
  LDA #>message_buffer
  STA $09
  PLA
  RTS
set_message_crlf:
  PHA
  LDA #<message_crlf
  STA $08
  LDA #>message_crlf
  STA $09
  PLA
  RTS

;
delay_6551:
  phy
  phx
delay_loop:
  ldy #1
minidly:
  ldx #$68
delay_1:
  dex
  bne delay_1
  dey
  bne minidly
  plx
  ply
delay_done:
  rts

;
; Buffer Routines
;
write_acia_buffer:      ; store char into buffer and increment pointer
  LDX ACIA_WR_PTR
  STA ACIA_BUFFER, x
  INC ACIA_WR_PTR
  RTS
read_acia_buffer:       ; read char from buffer and move pointer
  LDX ACIA_RD_PTR
  LDA ACIA_BUFFER, x
  RTS
acia_buffer_diff:       ; subtract buffer pointers. if there's a difference then written and need to read
  LDA ACIA_WR_PTR
  SEC
  SBC ACIA_RD_PTR
  RTS


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
