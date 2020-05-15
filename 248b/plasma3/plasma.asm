***************
* Plasma 3
* 25 Bytes free!
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

//->	stz	pal_off
	jsr	gen_pal

	lda	#102
	sta	y
	ldy	#0
.ly
	lda	#160
	sta	x
.lx
	stz	MATHE_AKKU

	lda	x
//->	lsr
//->	jsr	get_sin
	tax
	jsr	mulAX

	lda	y
//->	jsr	get_cos
	tax
	jsr	mulAX

	lda	x
	ldx	y
	jsr	mulAX

	lda	x
	sbc	#80
	jsr	get_sin
	pha
	lda	y
	sbc	#51
	jsr	get_cos
	plx
	jsr	mulAX

	lda	MATHE_AKKU
	lsr
	lsr

;;;------------------------------
;;; plot
;;;------------------------------
	// A = color
	sta	temp
	asl
	asl
	asl
	asl
	sta	temp+1
	lda	x
	lsr
	lda	(screen),y
	bcs	.lownibble
	and	#$0f
	ora	temp+1
	bra	.3
.lownibble:
	and	#$f0
	ora	temp
.3
	sta	(screen),y
	bcc	.1
	iny
	bne	.1
	inc	screen+1
.1
	dec	x
	bne	.lx
	dec	y
	bne	.ly

;;;------------------------------
endless::
;;;------------------------------
	ldx	#1
.vbl
	jsr	waitVBL
	dex
	bpl	.vbl
.2
	jsr 	waitVBL

	inc	pal_off
	jsr	gen_pal
	bra 	endless
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
	lda	#102
.1
	cmp	$fd0a
	bne	.1
.2
	cmp	 $fd0a
	beq	.2
	rts

;;;------------------------------
gen_pal::
;;;------------------------------
	ldy	#15
.1
	tya
	clc
	adc	pal_off
	asl
	jsr	get_sin
//->	lsr
	sta	$fda0,y
	tya
	adc	pal_off
	asl
	jsr	get_sin
	sta	temp
	tya
	jsr	get_cos
	asl
	asl
	asl
	asl
	ora	temp
	sta	$fdb0,y
	dey
	bpl .1
;;->	rts		; falling thru does not "hurt"

get_cos::
	clc
	adc	#8
get_sin::
	and	#$1f
	lsr
	tax
	lda	sin,x
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
