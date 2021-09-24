; zero page pointers to hold addresses for the target via device.
;
ZP_VIA_PORTB = $00
ZP_VIA_PORTA = $02
ZP_VIA_DDRB  = $04
ZP_VIA_DDRA  = $06

VIA1 = $6000
; VIA2 = $6000

VIA1_PORTB = VIA1   ; output register b
VIA1_PORTA = VIA1+1 ; output register a
VIA1_DDRB  = VIA1+2 ; data direction register b
VIA1_DDRA  = VIA1+3 ; data direction register a
VIA1_T1CL  = VIA1+4 ; t1 counter low byte
VIA1_T1CH  = VIA1+5 ; t1 counter high byte
VIA1_T1LL  = VIA1+6 ; t1 latches low byte
VIA1_T1LH  = VIA1+7 ; t1 latches high byte
VIA1_T2CL  = VIA1+8 ; t2 latches low byte
VIA1_T2CH  = VIA1+9 ; t2 latches high byte
VIA1_SHIFT = VIA1+$a ; shift refister
VIA1_ACR   = VIA1+$b ; auxillary control register
VIA1_PCR   = VIA1+$c ; peripheral control register
VIA1_IFR   = VIA1+$d ; interrupt flag register
VIA1_IER   = VIA1+$e ; interrupt enable register


E  = %10000000
RW = %01000000
RS = %00100000

  .code

reset:
  sei             ; interrupts off
  ldx #$ff
  txs


  lda #%00000000    ; low byte for latches
  sta VIA1_T1LL
  lda #%11111111    ; high byte for latches
  sta VIA1_T1LH

  ;
  lda #%00000000    ; low and high byte of counter
  sta VIA1_T1CL
  lda #%00000001
  sta VIA1_T1CH
  ;
  lda #%01000000    ; continuous interrupts, pb7 disabled
  ;lda #%11000000   ; pb7 square wave output
  sta VIA1_ACR
  ;
  lda #%00111111    ; clear all other interrupts
  sta VIA1_IER
  lda #%11000000    ; set t1 interrupts ($c0)
  sta VIA1_IER


  jsr set_via1      ; point to via1
  jsr lcd_init      ; initialize lcd

  cli               ; interrupts on

  ;jmp loop           ; !!!!!!!!!!!! SKIP AND START LOOPING

  ldy #0
print:
  lda message,y
  beq loop
  jsr print_char
  iny
  jmp print


;
;

loop:
  jmp loop

message: .asciiz "Starting."


lcd_init:
  pha

  ldx #0
  lda #%11111111 ; Set all pins on port B to output
  sta (ZP_VIA_DDRB,x) ; $6002 ; ZP_VIA, VIA_DDRB
  ;lda #%11100000 ; Set top 3 pins on port A to output
  lda #%11100001 ; Set top 3 pins on port A to output
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
  pha
  bit VIA1_T1CL       ; clear interrupt flag

  lda #%00000001
  sta (ZP_VIA_PORTA,x)
  lda #%00000000
  sta (ZP_VIA_PORTA,x)

  pla
  rti                 ; do nothing when interrupt fired
  ;jmp irq

  .segment "VECTORS" ; .org $fffa
  .word nmi
  .word reset
  .word irq
