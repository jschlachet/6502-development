
;
ZP_VIA_PORTB = $00
ZP_VIA_PORTA = $02
ZP_VIA_DDRB  = $04
ZP_VIA_DDRA  = $06

E  = %10000000
RW = %01000000
RS = %00100000


  .code


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

message: .asciiz "LCD Test 3"
message_2: .asciiz "LCD Test 2"


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

  lda #$00   ; $80 - via_portb == $6000
  sta $00
  lda #$60
  sta $01

  lda #$01   ; $82 - via_porta == $6001
  sta $02
  lda #$60
  sta $03

  lda #$02   ; $84 - via_ddrb == $6002
  sta $04
  lda #$60
  sta $05

  lda #$03   ; $86 - via_ddra == $6003
  sta $06
  lda #$60
  sta $07

  pla
  rts

;
;

set_via2:
  pha

  lda #$00   ; $40 - via_portb == $4000
  sta $00
  lda #$40
  sta $01

  lda #$01   ; $42 - via_porta == $4001
  sta $02
  lda #$40
  sta $03

  lda #$02   ; $44 - via_ddrb == $4002
  sta $04
  lda #$40
  sta $05

  lda #$03   ; $46 - via_ddra == $4003
  sta $06
  lda #$40
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

  .segment "VECTORS"
  .word nmi
  .word reset
  .word irq
