;
; LCD 1602 in 4-bit mode and connected solely to PORT A
;
; Execellent notes: 
; http://web.alfredstate.edu/faculty/weimandn/lcd/lcd_initialization/lcd_initialization_index.html

; zero page pointers to hold addresses for the target via device.
;
ZP_VIA_PORTB = $00
ZP_VIA_PORTA = $02
ZP_VIA_DDRB  = $04
ZP_VIA_DDRA  = $06

VIA1 = $5000
VIA2 = $6000

VIA1_PORTB = VIA1
VIA1_PORTA = VIA1+1
VIA1_DDRB  = VIA1+2
VIA1_DDRA  = VIA1+3

VIA2_PORTB = VIA2
VIA2_PORTA = VIA2+1
VIA2_DDRB  = VIA2+2
VIA2_DDRA  = VIA2+3

E             = %00010000
RW            = %00100000
RS            = %01000000
CLEAR_E       = %11101111
CLEAR_E_RW_RS = %10001111

  .code ; .org $8000

reset:
  ldx #$ff              ; (2)
  txs                   ; (2)

  JSR set_via2

  ; initialize via port a
  LDX #0
  LDA #$ff
  STA (ZP_VIA_DDRA,x)
  LDA $00
  STA (ZP_VIA_PORTA,x)

  ; right display
  ; jsr set_via1          ; (6)
  ; jsr lcd_init          ; (6)

  ; left display  ; SINGLE PORT USE - PORT A
  JSR lcd_init

  LDA #%01111111        ; (2) all but top pin of A are output
  STA (ZP_VIA_DDRA,x)   ; (6) set direction register

  JSR delay_25ms
  JSR delay_25ms
 
  JMP print_hello
  

print_hello:
  jsr set_via2
  ldy #0
print_loop:
  lda message_2,y
  beq loop
  jsr print_char
  iny
  jmp print_loop

loop:
  jmp loop

message_2: .asciiz "LCD 4bit mode!"

lcd_init:
  PHA                   ; 
  LDX #0                ; will be using X=0 repeatedly
  LDA #%01111111        ; all but top pin of A are output
  STA (ZP_VIA_DDRA,x)   ; set direction register
  LDA #$00
  STA (ZP_VIA_PORTA,x)  ; also initialize port a

  ; 1. Wait at least 100ms after power-on
  JSR delay_25ms
  JSR delay_25ms
  JSR delay_25ms
  JSR delay_25ms
  
  ; 2. Write 0x03 to LCD and wait 5 msecs
  LDA #$03
  STA (ZP_VIA_PORTA,x)
  JSR lcd_instruction_nowait
  JSR delay_5ms
 
  ; 3. Write 0x03 to LCD and wait 200 usecs
  LDA #$03
  STA (ZP_VIA_PORTA,x)
  JSR lcd_instruction_nowait
  JSR delay_200us
 
  ; 4. Write 0x03 to LCD and wait 160 usecs (or poll the busy flag)
  LDA #$03
  STA (ZP_VIA_PORTA,x)
  JSR lcd_instruction_nowait
  JSR delay_200us
  
  ; 5. Write 0x02 to enable 4-bit mode.
  LDA #$02
  STA (ZP_VIA_PORTA,x)
  JSR lcd_instruction_nowait
  JSR delay_200us
  
  ; -- at this point every command will take two nibble writes --

  ; 6. function set - Write set interface length
  LDA #$02              ; 001 (Function Set_, DL=0 (4-bit)
  JSR lcd_instruction
  LDA #$08              ; N=1 (2 lines), F=0 (5x8 font), X, X
  JSR lcd_instruction_nowait

  ; 7. Write 0x01/0x00 to turn off the Display
  LDA #$00
  JSR lcd_instruction
  LDA #$08
  JSR lcd_instruction_nowait

  ; 8. Write 0x00/0x01 to clear the Display;
  LDA #$00
  JSR lcd_instruction
  LDA #$01
  JSR lcd_instruction_nowait
  JSR lcd_wait

  ; 9. Write Set Cursor Move Direction setting cursor behavior bits
  LDA #$00
  JSR lcd_instruction
  LDA #$06
  JSR lcd_instruction_nowait

  ; 10. lcd initialization is now complete
  ; lcd is busy for a while here

  ; 11. Write Enable Display/Cursor to enable display and optional cursor
  LDA #$00
  JSR lcd_instruction
  LDA #$0e
  JSR lcd_instruction_nowait

  PLA
  RTS


; precise delay routine by dclxvi in the 6502 forums.
; A and Y are high and low bytes of a 16 bit value.
; cycle count == multiply 16bit value by 9, then add 8.
; Ref: http://forum.6502.org/viewtopic.php?f=12&t=5271&start=0#p62581
; 15ms = (9*1666)+8 --> 00000110 10000010 $06 $82
;
delay_ay:
  CPY #1                ; (2)
  DEY                   ; (2)
  SBC #0                ; (2)
  BCS delay_ay          ; (3)
  RTS

delay_5ms:
  PHA
  PHY
  LDA #$02
  LDY #$2b
  JSR delay_ay
  PLY
  PLA
  RTS

delay_200us:
  PHA
  PHY
  LDA #$00
  LDY #$11
  JSR delay_ay
  PLY
  PLA
  RTS

delay_15ms:
  PHA
  PHY
  LDA #$06
  LDY #$82
  JSR delay_ay
  PLY
  PLA
  RTS

delay_25ms:
  PHA
  PHY
  LDA #$0b
  LDY #$67
  JSR delay_ay
  PLY
  PLA
  RTS

set_via1:
  pha

  lda #<VIA1_PORTB      ; via_portb
  sta $00
  lda #>VIA1_PORTB
  sta $01

  lda #<VIA1_PORTA      ; via_porta
  sta $02
  lda #>VIA1_PORTA
  sta $03

  lda #<VIA1_DDRB       ; via_ddrb
  sta $04
  lda #>VIA1_DDRB
  sta $05

  lda #<VIA1_DDRA       ; via_ddra
  sta $06
  lda #>VIA1_DDRA
  sta $07

  pla
  rts

;
;

set_via2:
  pha

  lda #<VIA2_PORTB      ; via_portb
  sta $00
  lda #>VIA2_PORTB
  sta $01

  lda #<VIA2_PORTA      ; via_porta
  sta $02
  lda #>VIA2_PORTA
  sta $03

  lda #<VIA2_DDRB       ; via_ddrb
  sta $04
  lda #>VIA2_DDRB
  sta $05

  lda #<VIA2_DDRA       ; via_ddra
  sta $06
  lda #>VIA2_DDRA
  sta $07

  pla
  rts


; for now we're just going to clobber 7. we should read, 
; change the bits we need to modify, and then store.  
lcd_wait:
  PHA
  LDX #0
  LDA #%01110000  ; control lines output, data lines input
  STA (ZP_VIA_DDRA,x)
lcd_busy:
  LDA #RW
  STA (ZP_VIA_PORTA,x)
  LDA #(RW | E)
  STA (ZP_VIA_PORTA,x)
  LDA (ZP_VIA_PORTA,x)

  ; since we're in 4bit mode, reads come in as two nibbles
  ; save what we got and do another read
  ; then pull back what we read first (high nibble)
  PHA
  LDA #RW
  STA (ZP_VIA_PORTA,x)
  LDA #(RW | E)
  STA (ZP_VIA_PORTA,x)
  LDA (ZP_VIA_PORTA,x)
  PLA

  AND #%00001000
  BNE lcd_busy

  LDA #%01111111        ; reset control and data lines to output
  STA (ZP_VIA_DDRA,x)

  LDA #0                ; reset state of port a
  STA (ZP_VIA_PORTA,x)

  PLA
  RTS



lcd_instruction:
  JSR lcd_wait
  JSR lcd_instruction_nowait
  RTS

lcd_instruction_nowait:
  STA (ZP_VIA_PORTA,x)
  ORA #E                ; set E bit
  STA (ZP_VIA_PORTA,x)
  AND #CLEAR_E          ; clear E bit
  STA (ZP_VIA_PORTA,x)
  RTS


print_char:
  JSR lcd_wait

  ; a contrains character to print
  LDX #0                ; needed for indirect addressing
  
  PHA                   ; push a onto stack
  LSR a                 ; shift right 4 bits
  LSR a
  LSR a
  LSR a

  ORA #RS               ; send high nibble first with RS set
  STA (ZP_VIA_PORTA,x)
  ORA #(E|RS)                ; set E bit
  STA (ZP_VIA_PORTA,x)
  AND #CLEAR_E_RW_RS          ; clear control bits
  STA (ZP_VIA_PORTA,x)
  
  PLA                   ; pull copy of A back from stack
  ;JSR lcd_wait
  ; PHA                   ; preserve a
  AND #$0f              ; clear upper nibble
  ORA #RS               ; set RS bit
  STA (ZP_VIA_PORTA,x)
  ORA #(E|RS)           ; set RS and E
  STA (ZP_VIA_PORTA,x)
  AND #CLEAR_E_RW_RS          ; clear E
  STA (ZP_VIA_PORTA,x)

  RTS

nmi:
irq:
  jmp irq

  .segment "VECTORS" ; .org $fffa
  .word nmi
  .word reset
  .word irq