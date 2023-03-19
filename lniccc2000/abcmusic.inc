; ABC music definition file

abc_repeat_cnt
	db 0,0,0,0
abc_repeat_hoffs
	db 0,0,0,0
sound_channel_duration
	db 0,0,0,0
cur_note
	db 0
abcsilence
	db 0

abc_note_length
	db 6,6,6,6
abc_note_volume
	db 64,64,64,64
abc_instrument_incr
	db 4,4,4,4
abc_instrument_maxlen
	db 4,4,4,4
abc_instrument_decr
	db 4,4,4,4
sound_channel_busy
	db 0,0,0,0
sound_channel_max_volume
	db 127,127,127,127
sound_channel_volume
	db 4,4,4,4
sound_channel_maxlen
	db 4,4,4,4

abc_score_ptr_lo
	ds 4
abc_score_ptr_hi
	ds 4

abc_bm:
	db $11,$22,$44,$88

abc_init::
	stz $fd20
	stz $fd28
	stz $fd30
	stz $fd38
        lda #%01011000
	sta $fd20+5
	sta $fd28+5
	sta $fd30+5
	sta $fd38+5

	lda #$ff
	sta $fd44       ; all channels off
	stz $fd50	; all channels to left and right

	stz abc_score_ptr
	ldx  #3
.abci
	lda #<abcsilence
	sta  abc_score_ptr_lo,x
	lda #>abcsilence
	sta  abc_score_ptr_hi,x
	dex
	bpl .abci

	php
	sei
 IFD _ABC_120HZ
 	lda #%10011000|_15625Hz
 ELSE
	lda #%10011000|_31250Hz
 ENDIF
	sta $fd01+SND_TIMER*4
	lda #129
	sta $fd00+SND_TIMER*4		; set up a 240Hz IRQ
	SETIRQVEC SND_TIMER,abcIRQ
	plp

	rts

; Set all scores to silent at startup
abc_silence::
	ldx #3
.loop
	lda #<abcsilence
	ldy #>abcsilence
	jsr abc_set_score
	dex
	bpl .loop
	rts

; Read in decimal ASCII number
; result is in abc_tmp
abc_read_number::
	stz abc_tmp
	stz abc_tmp+1
.abc_read_number1
	lda (abc_score_ptr),y

	cmp #"/"
	bcc .abc_read_number2
	cmp #"9"+1
	bcs .abc_read_number2

	iny
	_IFEQ
	   inc abc_score_ptr+1
	_ENDIF

	and #$0f
	pha
	phy
	lda abc_tmp
	ldy abc_tmp+1
	asl abc_tmp
	rol abc_tmp+1
	asl abc_tmp
	rol abc_tmp+1
	clc
	adc abc_tmp
	sta abc_tmp
	tya
	adc abc_tmp+1
	asl abc_tmp
	rol
	sta abc_tmp+1
	ply
	pla
	clc
	adc abc_tmp
	sta abc_tmp
	_IFCS
	  inc abc_tmp+1
	_ENDIF
	bra .abc_read_number1
.abc_read_number2
	lda abc_tmp
	rts
;----------------------------------------
; Activate score on channel X
; A - low address
; Y - high address
; C = 1 => new score set
;
abc_set_score::
	bit sound_channel_busy,x
	bmi .exit
	sta abc_score_ptr_lo,x
	tya
	sta abc_score_ptr_hi,x
	stz sound_channel_duration,x
	dec sound_channel_busy,x
	lda abc_bm,x
	trb $fd44
	sec
	rts
.exit
	clc
	rts

;----------------------------------------
; Music update, called either with 120Hz or 240Hz
;
; Note: Lenght of a note is max. 254!
;

abcIRQ::
	phy
	ldx #3
.loop
	txa
	asl
	asl
	asl
	sta abc_by8
	ldy abc_score_ptr_lo,x
	lda abc_score_ptr_hi,x
	sta abc_score_ptr+1
update_channel_x:
	bit sound_channel_busy,x
	bpl .next_channel
	lda sound_channel_duration,x
	beq parse_abc		; not finisd
	; note is playing
	inc			; Duration 255 is forever, good for engines
	_IFNE
	  dec sound_channel_duration,x
	_ENDIF
_update_channel_tail:
	lda sound_channel_maxlen,x
	_IFNE
	  dec sound_channel_maxlen,x
	  _IFEQ
	    stz sound_channel_max_volume,x
	  _ENDIF
	_ENDIF
	lda sound_channel_max_volume,x
	_IFEQ
	  ; silence
	  lda sound_channel_volume,x
	  _IFNE
	    ; decay time still going on
	    sec
	    sbc abc_instrument_decr,x
	    _IFCC
	      ; silence
	      lda #0
	    _ENDIF
	    sta sound_channel_volume,x
	  _ENDIF
	_ENDIF
	lda sound_channel_volume,x
	cmp sound_channel_max_volume,x
	_IFLO
	  ; attack time
	  clc
	  adc abc_instrument_incr,x
	  _IFCS
	    ; desired volume reached
	    lda sound_channel_max_volume,x
	  _ENDIF
	  cmp sound_channel_max_volume,x
	  _IFHI
	    ; desired volume reached
	    lda sound_channel_max_volume,x
	  _ENDIF
	  sta sound_channel_volume,x
	_ENDIF
update_channel_tail:
	lda sound_channel_volume,x
.next_channel
	phy
	ldy abc_by8
	sta $fd20,y
	pla
	sta abc_score_ptr_lo,x
	lda abc_score_ptr+1
	sta abc_score_ptr_hi,x
	dex
	bpl .loop

	ply
	END_IRQ


; Parse score enough to get next note
; X - channel to use
; Y - abc music pointer
parse_abc::
	jsr abc_read_char
	cmp #$0 ; End of music
	_IFEQ
	  stz sound_channel_busy,x
	  stz sound_channel_volume,x
	  lda abc_bm,x
	  tsb $fd44
	  bra update_channel_tail
	_ENDIF
	cmp #' '		;ignore spaces
	beq parse_abc
	cmp #'|'
	_IFEQ
	  jsr abc_read_char
	  cmp #':'
	  _IFEQ
	    jsr	abc_read_number
	    _IFEQ
	      lda #255
	    _ENDIF
	    sta abc_repeat_cnt,x
	    sty abc_repeat_offs,x
	    lda abc_score_ptr+1
	    sta abc_repeat_hoffs,x
	  _ENDIF
	  bra parse_abc
	_ENDIF
	cmp #':'
	_IFEQ
	  dec abc_repeat_cnt,x
	  _IFNE
	    ldy abc_repeat_hoffs,x
	    sty abc_score_ptr+1
	    ldy abc_repeat_offs,x
	  _ENDIF
	  bra parse_abc
	_ENDIF
	cmp #'P'	;priority - wait until sound has ended
	_IFEQ
	  sta sound_channel_busy,x
	  bra parse_abc
	_ENDIF
	cmp #'V'	; volume
	_IFEQ
	  jsr abc_read_number
	  sta abc_note_volume,x
	  bra parse_abc
	_ENDIF
	cmp #'R'		; ramp up
	_IFEQ
	  jsr abc_read_number
	  sta abc_instrument_incr,x
	  bra parse_abc
	_ENDIF
	cmp #'H'		; hold
	_IFEQ
	  jsr abc_read_number
	  sta abc_instrument_maxlen,x
	  bra parse_abc
	_ENDIF
	cmp #'K'		; decay
	_IFEQ
	  jsr abc_read_number
	  sta abc_instrument_decr,x
	  jmp parse_abc
	_ENDIF
	cmp #'I'		; incremental
	_IFEQ
	  jsr abc_read_char
	  phx
	  ldx abc_by8
	  cmp #'0'
	  _IFEQ
	    lda #$df
	    and $fd25,x
	  _ELSE
	    lda #$20
	    ora $fd25,x
	  _ENDIF
	  sta $fd25,x
	  plx
	  jmp parse_abc
	_ENDIF
	cmp #'T'		; tempo
	_IFEQ
	  jsr abc_read_number
	  sta abc_note_length,x
	  jmp parse_abc
	_ENDIF
	cmp #'O'		; octave
	_IFEQ
	  jsr abc_read_char
	  sec
	  sbc #'0'
	  _IFCS
	    cmp #6
	    _IFCC
	       ora #$18
	       sta .smc1+1
	       phx
	       ldx abc_by8
	       lda $fd25,x
	       and #$b8
.smc1	       ora #0
	       sta $fd25,x
	       plx
	     _ENDIF
	   _ENDIF
	   jmp parse_abc
	_ENDIF
	cmp #'X'		; XOR taps
	_IFEQ
	  jsr abc_read_number
	  phx
	  ldx abc_by8
	  sta $fd21,x
	  stz $fd23,x
	  stz $fd27,x
;;->	  ror abc_tmp+1
;;->	  ror abc_tmp+1
;;->	  lda #$7f
;;->	  trb abc_tmp+1
;;->	  and $fd25,x
;;->	  ora abc_tmp+1
;;->	  sta $fd25,x
	  plx
	  jmp parse_abc
	_ENDIF
	cmp #'z'
	_IFEQ
	  lda #0
	  bra set_pause
	_ENDIF
	; Find out the pitch of the note
	stz cur_note
	inc cur_note
	cmp #'='
	_IFEQ
	  inc cur_note
	  jsr abc_read_char
	_ENDIF
	cmp #'~'
	_IFEQ
	  dec cur_note
	  jsr abc_read_char
	_ENDIF
	sec
	sbc #'A'
	cmp #'H'-'A'
	_IFLO
	  asl
	  adc cur_note
	_ELSE
	  sec
	  sbc #$20 ;'a'-'A' + 15
	  asl
	  adc cur_note
	  adc #15
	_ENDIF
	phy
	sta cur_note
	tay
	phx
	ldx abc_by8
	lda _delays,y
	sta $fd24,x
	plx
	ply

	; Find out the volume of the note
	lda abc_note_volume,x
set_pause:
	sta sound_channel_max_volume,x

	; Find out the duration of the note
	jsr abc_read_number
	_IFEQ
	  lda #255
	_ELSE
	  phy
	  tay
	  clc
	  lda	#0
.durloop
	  adc  abc_note_length,x
	  bcs .maxlen
	  dey
	  bne .durloop
	  SKIP2
.maxlen	  lda	#254
	  ply
	_ENDIF

	sta sound_channel_duration,x
	lda abc_instrument_maxlen,x
	sta sound_channel_maxlen,x
	jmp update_channel_x

; Read a character from the score. Advance ptr if it is not 0
; X - channel
; Y - score offset
abc_read_char::
	lda (abc_score_ptr),y
	iny
	_IFNE
	  rts
	_ENDIF
	inc abc_score_ptr+1
	rts

; This table is used to cover the delays needed for 2 octaves
_delays db 161 ; Ab
	db 152 ; A
	db 143 ; A# Bb
	db 135 ; B
	db 128 ;
	db 255 ; C
	db 241 ; C# Db
	db 227 ; D
	db 214 ; D# Eb
	db 202 ; E
	db 191 ;
	db 191 ; F
	db 180 ; F# Gb
	db 170 ; G
	db 161 ; G#
_delays2
	db 80  ; ab
	db 76  ; a
	db 72  ; a# bb
	db 68  ; b
	db 128 ;
	db 128 ; c
	db 120 ; c# db
	db 114 ; d
	db 107 ; d# eb
	db 101 ; e
	db 96  ;
	db 96  ; f
	db 90  ; f# gb
	db 85  ; g
	db 80  ; g#
