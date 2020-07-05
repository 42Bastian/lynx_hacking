***************
* rotz! - ROToZoomer (with sound)!
* 0 bytes free
* (c) 42Bastian / June 2020
****************

	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/suzy.mac>

 BEGIN_ZP
screen	ds 2
x	ds 1
y	ds 1
temp	ds 2
rot	ds 1
si	ds 2
co	ds 2
u0	ds 2
v0	ds 2
u	ds 2
v	ds 2
 END_ZP
;;; ROM sets this address
screen0	 equ $2000

 IFD LNX
	run	$200
 ELSE
	;; BLL loader is at $200, so move up
	run	$400
 ENDIF

 IFND LNX
	;; Setup needed if loaded via BLL/Handy
	lda	#8
	sta	$fff9
	cli
	lda	#$20
	stz	$fd94
	stz	screen
	sta	$fd95

	stz 	$fd50
	stz	temp

	ldx	#0
	ldy	#8192/256
.cls
	stz	$2000,x
.cls1
	stz	$6000,x
	inx
	bne	.cls
	inc	.cls+2
	inc	.cls1+2
	dey
	bpl	.cls
	ldy	#2

	ldx	#31
	lda	#$ff
.init
	sta	$fda0,x
	dex
	bne	.init
 ENDIF
;;; ---------------------------------------------------------------------------
Start::
	;; expand sin/cos table and set colors
	ldx	#15
.122
	lda	sin,x		; 1st quadrant
	sta	sin+16-2,y	; => 2nd quadrant (y == 2 after ROM)
	eor	#$ff
	inc
	sta	sin+32,x	; => 3rd quadrant

	txa
	asl
	sta	$fdb0,x
	sta 	$fda0,x

	iny
	dex
	bpl	.122

	lda	#$98|6
	sta	$fd25
	lda	#0x83
	sta	$fd21
;;; ----------------------------------------
;;; main loop
;;; ----------------------------------------
.again:

.rot
	lda	#31
	and	#31		; only 0..90° (rotating squares)
	inc	.rot+1		; Selfmod safes 1 byte ;-)
	tax

.v1
	ldy	$fd0a		; waitVBL
	bne	.v1

.round				; double buffering
	lda	#$20
	sta	screen+1	; draw screen
	eor	#$40
	sta	.round+1
	stz	screen
	sta	$fd95		; visible screen

	lda	sin,x		; X = angle
	asl
	asl			; scaling
	sta	si
	sta	$fd20		; sound :-)
	sta	v0
	stz	v0+1

;;->	ldy	#0		; y == 0 from waitVBL
	lda	sin+16,x
	bpl	.p
	dey			; sign extend
.p	sta	co
	sty	co+1

	;; Rotate around (32,32)
	;; u0 = -32*co+32*si
	;; v0 = -32*si-32*co
	eor	#$ff
	tax
	tya
	eor	#$ff
	inx
	bne	.nm
	inc
.nm	sta	temp
	txa			; a:temp = -co

	ldx	#5
.25si
	asl	v0
	rol	v0+1		; sin*2
	asl
	rol	temp		; cos*2
	dex
	bne	.25si
	tax			; x:temp = -32*co, v0 = 32*si

	clc			; u0 = 32*si - 32*co
	adc	v0
	sta	u0
	lda	temp
	adc	v0+1
	sta	u0+1

	sec			; v0 = -32*si - 32*co
	txa
	sbc	v0
	sta	v0
	lda	temp
	sbc	v0+1
	sta	v0+1

	;; paint screen

	lda	#50
	sta	y
.ly
	MOVE	v0,v
	MOVE	u0,u
	ldy	#0
.lx
	;; "Texture"
;;->	lda	u+1		; done above or end of loop
	eor	v+1
	and 	#%101
//->	asl
//->	and #31
//->	tax
//->	lda	sin,x
//->	lsr
	sta	(screen),y
	iny

	clc			;v += si
	lda	si
	adc	v
	sta	v
	bcc	.14
	inc	v+1
.14
	ldx	#u		; u += co
	jsr	add_co

	cpy	#80
	bne	.lx

	tya
	asl			; "asl" clears Carry
//->	clc
	adc	screen
	sta	screen
	bcc	.141
	inc	screen+1
.141
	sec			;u0 -= si
	lda	u0
	sbc	si
	sta	u0
	bcs	.15
	dec	u0+1
.15
	ldx	#v0
	jsr	add_co		;v0 += co

	dec	y
	bpl	.ly

	lbra	.again

add_co::
	clc			;v0 += co
	lda	0,x
	adc	co
	sta	0,x
	lda	1,x
	adc	co+1
	sta	1,x
	rts

sin:
	dc.b $01,$03,$06,$09,$0c,$0f,$11,$14
	dc.b $16,$18,$1a,$1c,$1d,$1e,$1f,$1f
	dc.b $42
End:
 IFND LNX
	dc.b 0
 ENDIF
size	set End-Start
free 	set 249-size

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree"
