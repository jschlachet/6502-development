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
