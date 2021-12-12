***************
* Starfield with 256 stars
* 9 bytes free.
****************

	include <includes/hardware.inc>
	include <macros/help.mac>

;;; ROM sets this address
screen0	 equ $2000

 BEGIN_ZP
frame		ds 1
plot_color	ds 1
plot_x		ds 1
plot_y		ds 1
rng_zp_low	ds 1
rng_zp_high	ds 1
ptr		ds 2
 END_ZP

stars_x		equ $4100
stars_y		equ $4200
stars_z		equ $4300

	run	$200

 IFND LNX
	;; Setup needed if loaded via BLL/Handy as .o file
	lda	#8
	sta	$fff9
	sei
	ldx	#14
.init
	lda	#$ff
	sta	$fda0,x
	sta	$fdb0,x
	dex
	bne	.init
	stz	$fdaf
	stz	$fdbf
	stz	$fda0
	stz	$fdb0

	ldy	#8192/256
.clr
	stz	$2000,x
	inx
	bne	.clr
	inc	.clr+2
	dey
	bpl	.clr

	lda	#$fa
	sta	5
	stz	0

	ldy	#2
	lda	#0
	tax
 ENDIF

Start::
;;; --------------------
;;; grayscale palette
	clc
	txa			; X = 0 after ROM
.pal
	  sta	$fda0,x
	  sta	$fdb0,x
	  inx
	  adc	#$11
	bcc	.pal

;;; Init sound
	lda	#AUD_RESETDONE|AUD_RELOAD|AUD_CNTEN|AUD_16us
	sta	CONTRL_A
	lda	#$90
	sta	FEEDBACK_A
	lsr
	sta	VOLUME_A

main::
;;;------------------------------
;;; Swap screens
.swp
	lda	#$20
	sta	DISPADRH
	eor	#$40
	sta	.swp+1
	stz	ptr
	sta	ptr+1
;;;------------------------------
;;; wait VBL
.v0
	lda	$fd0a
	bne	.v0

;;;------------------------------
	tax
	inc	frame
	lda	frame
	cmp	#192
	bcs	.noclr
.clr0
	txa
	tay
	ldx	#$20
.clr	sta	(ptr),y
	iny
	bne	.clr
	inc	ptr+1
	dex
	bne	.clr
	lda	#$30*2
.noclr
	lsr
	sta	FREQ_A
.loop
	lda	stars_z,x
	bne	.ok
.next
;;;------------------------------
;; Random
;; (from codebase64)
	LDA rng_zp_high
	LSR
	LDA rng_zp_low
	ROR
	EOR rng_zp_high
	STA rng_zp_high ; high part of x ^= x << 7 done
	ROR		; A has now x >> 9 and high bit comes from low byte
	EOR rng_zp_low
	STA rng_zp_low	; x ^= x >> 9 and the low part of x ^= x << 7 done
	EOR rng_zp_high
	STA rng_zp_high ; x ^= x << 8 done
;;;------------------------------
	sta	stars_x,x

	lda	rng_zp_low
	sta	stars_y,x

	lda	#31
	sta	stars_z,x
.ok
	sta	MATHE_B		; prepare multiplication

	lsr
	eor	#$f
	sta	plot_color

	lda	stars_x,x
	jsr	project
	adc	#80
	sta	plot_x
	cmp	#160		; outside screen, new star
	bcs	.next

	lda	stars_y,x
	jsr	project
	adc	#51
	bmi	.next
	sta	plot_y
	cmp	#102
	bcs	.next

	sta	MATHE_C
	lda	#80
	sta	MATHE_E+1
.ws
	bit	SPRSYS
	bmi	.ws

//->	clc			; c = 0 from above
	lda	MATHE_A+1
	sta	ptr
	lda	MATHE_A+2
	adc	.swp+1
	sta	ptr+1

	lda	plot_x
	lsr
	tay
	lda	plot_color
	bcs	.1
	asl
	asl
	asl
	asl
.1
	ora	(ptr),y
	sta	(ptr),y
.skip
	dec	stars_z,x
	inx
	bne	.loop
	lbra	main

;;; --------------------
;;;
;;; ret = 16*xy/z;

project::
	tay			; save sign
	bpl	.0
	eor	#$ff
	inc
.0
	sta	MATHE_C
	lda	#16
	sta	MATHE_E+1	;kick mult
.2
	bit	SPRSYS
	bmi	.2

	stz	MATHE_A+3	;kick divide
.3
	bit	SPRSYS
	bmi	.3

	lda	MATHE_D+1
	cpy	#0
	bmi	.4
	eor	#$ff		; negate result
	inc
.4
	clc
	rts

End:
	IFND LNX
	;; Lynx rom clears to zero after boot loader!
	dc.b 0
 ENDIF
size	set End-Start
free	set 249-size

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree"
