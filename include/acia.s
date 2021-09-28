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
  BIT ACIA_STATUS ; TRY TO CLEAR STATUS
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
  PHX
  LDX ACIA_WR_PTR
  STA ACIA_BUFFER, x
  INC ACIA_WR_PTR
  PLX
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
