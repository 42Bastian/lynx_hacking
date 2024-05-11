***************
* plasmosis port
* post-Lovebyte 2024
* Size: 64
****************

	include <macros/help.mac>

;;; ROM sets this address
screen0	equ $2000
back	equ $4000

 BEGIN_ZP
ptr		ds 2
bptr		ds 2
tmp		ds 1
tmp1		ds 1
color_change	ds 1
color_change1	ds 1
 END_ZP


 IFD LNX
	run	$200
 ELSE
	run	$200-3
	jmp	init
 ENDIF
Start::
	dey
	sty	color_change
	sty	color_change1

	ldx	#$20
	stx	ptr+1
.co
	adc	$fd02
	sta	(ptr),y
	iny
	bne	.co
	inc	ptr+1
	dex
	bne	.co

.loop
	dec	color_change
	bne	.swp
	smb5	color_change
	inc	color_change1
	rmb2	color_change1
	ldx	#15
	txa
.ilut1
	ldy	color_change1
	beq	.cc
	txa
	dey
	beq	.cc
	eor	#$f1
.cc
	sta	$fda0,x
	rol
	sta	$fdb0,x
	dex
	bpl	.ilut1
	stz	$fdb0
//->	stz	$fda0
;;;------------------------------
;;; Swap screens
.swp	lda	#$40
	sta	$fd95
	eor	#$20
	sta	.swp+1
	sta	ptr+1
;;;------------------------------
;;; wait VBL
.v0
	lda	$fd0a
	bne	.v0

	stz	bptr
	stz	ptr
	lda	#$20
	sta	bptr+1
	sta	tmp
	lda	(bptr)
.fade
	dec
	sta	(bptr)
	adc	(bptr),y
	ror
	tax
	lsr
	and	#$f
	sta	(ptr)
	txa
	inc	bptr
	inc	ptr
	beq	.1
	dey
	bne	.2
	ldy	#80
	bra	.fade
.2	ldy	#1
	bra	.fade
.1
	inc	ptr+1
	inc	bptr+1
	dec	tmp
	bne	.fade
	bra	.loop

End:

size	set End-Start
free	set 128-size

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree"
;;; ----------------------------------------
 IFND LNX
init::
	;; Setup needed if loaded via BLL/Handy
	stz	$fff9
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

	stz	$fd94
	lda	#$20
	sta	$fd95
	lda	#$fa
	sta	5
	stz	0

	ldy	#2
	lda	#0
	tax

	jmp	Start
 ENDIF
