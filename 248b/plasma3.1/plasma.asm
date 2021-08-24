***************
* Plasma 3.1
* 11 Bytes free!
****************

	include <includes/hardware.inc>
* macros
	include <macros/help.mac>

*
* vars only for this program
*

 BEGIN_ZP
screen		ds 2
x		ds 1
y		ds 1
temp		ds 2
pal_off		ds 1
ptr		ds 2
 END_ZP

;;; ROM sets this address
screen0		equ $2000

 IFD LNX
	;; BLL loader is at $200, so move up
	run	$200
 ELSE
	run	$400
 ENDIF

 IFND LNX
	;; Setup needed if loaded via BLL/Handy
	lda	#8
	sta	$fff9
	cli
	stz	screen
	stz	$fd94
	lda	#$20
	sta	$fd95
 ENDIF
Start::
	lda	#USE_AKKU	; == $40
	sta	SPRSYS
	lsr
	sta	screen+1

	jsr	gen_pal

	lda	#166		; 64 lines more for scrolling
	sta	y
.ly
	lda	#160
	sta	x
.lx
	stz	MATHE_AKKU

	lda	x
	tax
	jsr	mulAX

	lda	y
	tax
	jsr	mulAX

	lda	x
	ldx	y
	jsr	mulAX

	lda	x
	sbc	#80
	jsr	get_sin
	tax
	lda	y
	sbc	#51
	jsr	get_cos
	jsr	mulAX

	ldx	MATHE_AKKU
;;;------------------------------
;;; plot
;;;------------------------------
	;; X = color*4
	lda	x
	lsr
	txa
	bcc	.11
	asl
	asl
	and	#$f0
	sta	temp
	bra	.12
.11
	lsr
	lsr
	and	#$f
	ora	temp
	sta	(screen)

	inc	screen
	bne	.12
	inc	screen+1
.12
	dec	x
	bne	.lx
	dec	y
	bne	.ly

;;;------------------------------
endless::
	stz	screen
	lda	#$20
	sta	screen+1
;;;------------------------------
.loop
	jsr	waitVBL

	lda	screen
	sta	$fd94
	lda	screen+1
	sta	$fd95

	clc			; "hardware" scrolling :-)
	lda	screen
	adc	#80
	sta	screen
	bcc	.3
	inc	screen+1
.3
	inc	pal_off
	jsr 	waitVBL
	jsr	gen_pal

	lda	screen+1
	cmp	#$34		; 64 lines scrolled?
	bne	.loop
	bra	endless
;;;------------------------------
mulAX::
;;;------------------------------
	sta	MATHE_C		; A = C * E
	stx	MATHE_E		; AKKU = AKKU + A
	stz	MATHE_E+1
//->.waitm1
//->	lda	SPRSYS
//->	bmi	.waitm1
	rts
;;;------------------------------
waitVBL::
;;;------------------------------
.1
	lda	$fd0a
	bne	.1
.2
	lda	$fd0a
	beq	.2
	rts
;;;------------------------------
gen_pal::
;;;------------------------------
	ldx	#15
.1
	txa
	clc
	adc	pal_off
	jsr	get_sin
	sta	$fda0,x
	txa
	adc	pal_off
	asl
	jsr	get_sin
	sta	temp
	txa
	jsr	get_cos
	asl
	asl
	asl
	asl
	ora	temp
	sta	$fdb0,x
	dex
	bpl .1
;;->	rts		; falling thru does not "hurt"

get_cos::
	clc
	adc	#8
get_sin::
	and	#$1f
	lsr
	tay
	lda	sin,y
	bcs	.99
	lsr
	lsr
	lsr
	lsr
.99
	and	#$f
	clc
	rts

sin:	dc.b $89,$ab,$cd,$ee
	dc.b $fe,$ed,$cb,$a9
	dc.b $76,$54,$32,$11
	dc.b $11,$12,$34,$56
****************

End:
size	set End-Start

free 	set 249-size

	echo "Size:%dsize  Free:%dfree"
	; fill remaining space
	IF free > 0
	REPT	free
	dc.b	$42		; unused space shall not be 0!
	ENDR
	ENDIF
