***************
* PurpleRay
* 2 bytes free.
****************

	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/if_while.mac>

GREEN0		EQU $FDA0
BLUERED0	EQU $FDB0

 BEGIN_ZP
ptr	ds 2
frame	ds 1
temp	ds 1
	;; Do not changed order of the next 6 variables
dx0	ds 2
dx_lo	ds 1
dx_hi   ds 1
dy0	ds 2
dy_lo	ds 1
dy_hi	ds 1

x	ds 1
y	ds 1
z	ds 1
color	ds 16
drawptr	ds 2
 END_ZP

	run	$200

 IFND LNX
	;; Setup needed if loaded via BLL/Handy
	lda	#8
	sta	$fff9
	sei

	stz	DISPADRL
	lda	#$20
	sta	DISPADRH
	ldx	#15
.init
	txa
	sta	GREEN0,x
	stz	BLUERED0,x
	dex
	bpl	.init
	stz	$fdaf

	inx
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
;;; ----------------------------------------
Start::
	tay			; clear Y

	clc
.col
	stz	GREEN0,x
	sta	color,x
	sta	BLUERED0,x
	inx
	adc	#$11
	bcc	.col

	lda	#$64
	sta	ptr+1
prepare::
	dec	BLUERED0
	lda	#51
	sta	y
.loopy
	lda	#80

.loopx
	pha
	ldx	#dx0
	jsr	mul64		; dx0 = (x-25); dx = (x-25)*64

	ldx	#dy0
	lda	y
	jsr	mul64		; dy0 = (y-25); dy = (y-25)*64

	lda	#31
	sta	z
.loop
	clc
	lda	frame
	adc	dx_hi
	and	z
	sta	temp
	clc
	lda	frame
	adc	dy_hi
	and	temp
	and	#4
	bne	.done

	clc
	lda	0+dx0
	adc	2+dx0
	sta	2+dx0
	lda	1+dx0
	adc	3+dx0
	sta	3+dx0

	clc
	lda	0+dy0
	adc	2+dy0
	sta	2+dy0
	lda	1+dy0
	adc	3+dy0
	sta	3+dy0

	dec	z
	bne	.loop
	lda	dx_hi
	eor	dy_hi
	and	#3
	tax
	bra	.col
	nop
.done
	lsr	z
	rmb0	z
	ldx	z
.col
	lda	color,x
	sta	(ptr),y
	iny
	_IFEQ
	  inc	ptr+1
	_ENDIF

	pla
	dec
	bne	.loopx

	dec	y
	bne	.loopy

	inc	frame
	rmb3	frame
	lda	frame
	bne	prepare
;;; ----------------------------------------
main::
	stz	drawptr
	lda	#$64
	sta	drawptr+1
.loop
	ldx	#4
.v0
	lda	VCOUNTER+TIM_CNT
	bne	.v0
.v1
	lda	VCOUNTER+TIM_CNT
	beq	.v1
	dex
	bpl	.v0
;;;------------------------------

	stz	ptr
.swp
	lda	#$04
	sta	ptr+1
	eor	#$40
	sta	.swp+1
	sta	DISPADRH

	ldx	#101
.ly
	ldy	#79
.lx
	  lda	(drawptr),y
	  sta	(ptr),y
	  dey
	bpl	.lx

	ldy	#80
	clc
	tya
	adc	ptr
	sta	ptr
	_IFCS
	  inc ptr+1
	_ENDIF
	txa
	lsr
	_IFCC
	   clc
	   tya
	   adc drawptr
	   sta drawptr
	   _IFCS
	     inc drawptr+1
	   _ENDIF
	_ENDIF
	dex
	bpl	.ly

	inc	frame
	rmb3	frame
	lda	frame
	bne	.loop
;;------------------------------
	bra	main

;;------------------------------
;;; a*64 = (a*256)/4
mul64::
	sec
	sbc	#25
	sta	0,x
	stz	1,x
	bpl	.1
	dec	1,x
.1
	stz	2,x
	cmp	#$80		; keep sign bit!
	ror
	ror	2,x
	cmp	#$80
	ror
	ror	2,x
	sta	3,x
	rts

 IFND LNX
	;; Lynx rom clears to zero after boot loader!
	dc.b 0
 ENDIF
End:
size	set End-Start
free	set 249-size

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree"
