; zero page pointers to hold addresses for the target via device.
;
ZP_VIA_PORTB = $00
ZP_VIA_PORTA = $02
ZP_VIA_DDRB  = $04
ZP_VIA_DDRA  = $06

VIA1 = $4000
VIA2 = $6000

VIA1_PORTB = VIA1
VIA1_PORTA = VIA1+1
VIA1_DDRB  = VIA1+2
VIA1_DDRA  = VIA1+3

VIA2_PORTB = VIA2
VIA2_PORTA = VIA2+1
VIA2_DDRB  = VIA2+2
VIA2_DDRA  = VIA2+3


E  = %10000000
RW = %01000000
RS = %00100000

  .code ; .org $8000

reset:
  ldx #$ff
  txs

  jsr set_via1
  jsr lcd_init

  jsr set_via2
  jsr lcd_init



  jsr set_via1
  ldy #0
print:
  lda message,y
  beq start_2
  jsr print_char
  iny
  jmp print


start_2:
  jsr set_via2
  ldy #0
print_2:
  lda message_2,y
  beq loop
  jsr print_char
  iny
  jmp print_2

loop:
  jmp loop

message: .asciiz "LCD Test 2"
message_2: .asciiz "LCD Test 1"


lcd_init:
  ldx #0
  lda #%11111111 ; Set all pins on port B to output
  sta (ZP_VIA_DDRB,x) ; $6002 ; ZP_VIA, VIA_DDRB
  lda #%11100000 ; Set top 3 pins on port A to output
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

;
;

set_via2:
  pha

  lda #<VIA2_PORTB ; via_portb
  sta $00
  lda #>VIA2_PORTB
  sta $01

  lda #<VIA2_PORTA ; via_porta
  sta $02
  lda #>VIA2_PORTA
  sta $03

  lda #<VIA2_DDRB ; via_ddrb
  sta $04
  lda #>VIA2_DDRB
  sta $05

  lda #<VIA2_DDRA ; via_ddra
  sta $06
  lda #>VIA2_DDRA
  sta $07

  pla
  rts

;
;

lcd_wait:
  pha
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
  ldx #0
  sta (ZP_VIA_DDRB,x)
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
  jsr lcd_wait
  ldx #0
  sta (ZP_VIA_PORTB,x)
  lda #RS         ; Set RS; Clear RW/E
  sta (ZP_VIA_PORTA,x)
  lda #(RS | E)   ; Set E bit to send instruction
  sta (ZP_VIA_PORTA,x)
  lda #RS         ; Clear E bits
  sta (ZP_VIA_PORTA,x)
  rts


nmi:
irq:
  jmp irq

  .segment "VECTORS" ; .org $fffa
  .word nmi
  .word reset
  .word irq
