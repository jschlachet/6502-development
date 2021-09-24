;

.setcpu "65C02"

VIA1 = $5000
;VIA2 = $6000

ZP_VIA_PORTB = $00
ZP_VIA_PORTA = $02
ZP_VIA_DDRB  = $04
ZP_VIA_DDRA  = $06
ZP_MESSAGE   = $08 ; message to send via serial

VIA1_PORTB = VIA1
VIA1_PORTA = VIA1+1
VIA1_DDRB  = VIA1+2
VIA1_DDRA  = VIA1+3

ACIA_DATA    = $4400
ACIA_STATUS  = $4401
ACIA_COMMAND = $4402
ACIA_CONTROL = $4403

E  = %10000000
RW = %01000000
RS = %00100000

ACIA_BUFFER   = $0200 ; 256 bytes, $200-$2FF
ACIA_RD_PTR   = $0300 ; 1 byte
ACIA_WR_PTR   = $0301 ; 1 byte


message_startup: .byte $0d, $0a, "Starting up.", $0d, $0a, $00 ; CR LF NULL
message_empty: .byte "Buffer empty.", $0d, $0a, $00
message_buffer: .byte $0d, $0a, "Buffer contents:", $0d, $0a, $00
message_crlf: .byte $0d, $0a, $00

  .code

reset:
  ldx #$ff
  txs

  ldx #0

  jsr set_via1
  jsr lcd_init

  ; make a dollar size prompt on lcd
  lda #$24 ; dollar sign
  jsr print_char

  jsr init_acia

  jsr set_message_startup
  jsr send_message

  cli                   ; clear interrupt (enable)
  jsr loop

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


loop:
  jmp loop

lcd_init:
  pha
  ldx #0
  lda #$ff ; Set all pins on port B to output
  sta (ZP_VIA_DDRB,x) ; $6002 ; ZP_VIA, VIA_DDRB
  lda #%11100000 ; Set top 3 pins on port A to output
  ldx #0
  sta (ZP_VIA_DDRA,x) ; $6003 ; ZP_VIA_DDRA ; VIA1_DDRA
  ;
  lda #%00111000 ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001 ; Clear display
  jsr lcd_instruction
  pla
  rts

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

set_via1:
  pha
  lda #<VIA1_PORTB ; via_portb
  sta $00
  lda #>VIA1_PORTB
  sta $01
  lda #<VIA1_PORTA ; via_porta
  sta $02
  lda #>VIA1_PORTA
  sta $03
  lda #<VIA1_DDRB ; via_ddrb
  sta $04
  lda #>VIA1_DDRB
  sta $05
  lda #<VIA1_DDRA ; via_ddra
  sta $06
  lda #>VIA1_DDRA
  sta $07
  pla
  rts

lcd_wait:
  pha
  phx
  lda #%00000000  ; Port B is input
  sta (ZP_VIA_DDRB,x)
lcdbusy:
  lda #RW
  ldx #0
  sta (ZP_VIA_PORTA,x)
  lda #(RW | E)
  sta (ZP_VIA_PORTA,x)
  lda (ZP_VIA_PORTB,x)
  and #%10000000
  bne lcdbusy

  lda #RW
  ldx #0
  sta (ZP_VIA_PORTA,x)
  lda #%11111111  ; Port B is output
  sta (ZP_VIA_DDRB,x)
  plx
  pla
  rts

lcd_instruction:
  jsr lcd_wait
  ldx #0
  sta (ZP_VIA_PORTB,x)
  lda #0         ; Clear RS/RW/E bits
  sta (ZP_VIA_PORTA,x)
  lda #E         ; Set E bit to send instruction
  sta (ZP_VIA_PORTA,x)
  lda #0         ; Clear RS/RW/E bits
  sta (ZP_VIA_PORTA,x)
  rts


print_char:
  PHA
  PHX
  jsr lcd_wait
  ldx #0
  sta (ZP_VIA_PORTB,x)
  lda #RS         ; Set RS; Clear RW/E
  sta (ZP_VIA_PORTA,x)
  lda #(RS | E)   ; Set E bit to send instruction
  sta (ZP_VIA_PORTA,x)
  lda #RS         ; Clear E bits
  sta (ZP_VIA_PORTA,x)
  PLX
  PLA
  RTS

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
