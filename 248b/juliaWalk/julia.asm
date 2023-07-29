***************
* JuliaWalk - 80x102 pixels
* 0 bytes free.
****************

	include <includes/hardware.inc>
	include <macros/suzy.mac>
	include <macros/help.mac>
	include <macros/if_while.mac>

 BEGIN_ZP
cr	ds 2
ptr	ds 2
ptr2	ds 2
r0	ds 2
i0	ds 2
r1	ds 2
i1	ds 2
r2	ds 2
i2	ds 2
ci	ds 2
iter	ds 2
tmp	ds 2
x	ds 1
 END_ZP

 IFND LNX
	run	$200-3
	jmp	bll_init
 ELSE
	run	$200
 ENDIF
;;; ----------------------------------------
Start::
	lda	#SIGNED_MATH
	sta	SPRSYS
	sta	cr
	ldy	#31
.pal
	tya
	sta	$fda0,y
	dey
	bpl	.pal

	dey
	sty	ci+1		; == >-333
	lda	#<(-333)
	sta	ci
;;->	lda	#94
;;->	sta	cr
//->	stz	cr+1
main::
;;;------------------------------

;;;------------------------------
;;; Swap screens
	lda	#<8159
	sta	ptr2
.swp
	lda	#$80
	sta	$fd95
	eor	#$40
	sta	.swp+1
;;;------------------------------
	sta	ptr+1
	clc
	adc	#>8159
	sta	ptr2+1
	ldy	#0
	MOVEI	-308,i0
	lda	#50
ly:
	pha
	MOVEI	-478,r0
	lda	#79
	sta	x
lx:
	ldx	#3
.cpy	  lda	r0,x
	  sta	r1,x
	  dex
	bpl	.cpy
	stx	iter
	phy
	jsr	iter_loop
	ply
	sta	(ptr),y
	iny
	_IFEQ
	  inc	ptr+1
	_ENDIF
	sta	(ptr2)
	lda	ptr2
	_IFEQ
	  dec ptr2+1
	_ENDIF
	dec	ptr2

	lda	#6*2
	ldx	#r0
	jsr	add2

	dec	x
	bpl	lx

	ldx	#i0
	jsr	add

	pla
	dec
	bpl	ly

	ldx	#ci
	jsr	add
	bra	main

add:
	lda	#6
add2:
	clc
	adc	0,x
	sta	0,x
	_IFCS
	  inc 1,x
	_ENDIF
	rts

iter_loop::
	ldx	i1
	lda	i1+1
	jsr	square
	sta	i2
	stx	i2+1

	ldx	r1
	lda	r1+1
	jsr	square
	sta	r2
	stx	r2+1

	adc	i2
	txa
	adc	i2+1
	cmp	#4
	bcs	.done

	sec
	lda	r2
	sbc	i2
	tax
	lda	r2+1
	sbc	i2+1
	tay

//->	clc
	txa
	adc	cr
	sta	r1
	tya
	adc	cr+1
	sta	r1+1

	lda	i1
	asl
	tax
	lda	i1+1
	rol
	jsr	mul

	adc	ci
	sta	i1
	txa
	adc	ci+1
	sta	i1+1
	sec
	lda	iter
	sbc	#$11
	sta	iter
	bne	iter_loop
.done
	lda	iter
	rts
	;; Y:A = A:X*A:X

square::
	stx	MATHE_C
	sta	MATHE_C+1
	;; Y:A = MATHE_C * A:X
mul::
	stx	MATHE_E
	sta	MATHE_E+1

	WAITSUZY
	;; normalize
	lda	MATHE_A+1
	ldx	MATHE_A+2
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
;;; ----------------------------------------------------------------------
 IFND LNX
bll_init:

	;; Setup needed if loaded via BLL/Handy
	lda	#8
	sta	$fff9
	sei

	stz	DISPADRL
	lda	#$20
	sta	DISPADRH
	ldx	#15
	lda	#$ff
.init
	sta	GREEN0,x
	sta	BLUERED0,x
	sec
	sbc	#$11
	dex
	bpl	.init
	stz	$fdaf

	lda	#16
	sta	$fc08

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
	stz	1
	stz	2
	stz	3

	ldy	#2
	lda	#0
	tax
	jmp	$200
 ENDIF
	echo "Size:%dsize  Free:%dfree"
