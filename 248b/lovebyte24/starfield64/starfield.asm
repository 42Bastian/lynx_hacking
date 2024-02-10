***************
* Starfield64
* Release: Lovebyte 2024
* Size: 63
****************

	include <macros/help.mac>
	include <macros/if_while.mac>

;;; ROM sets this address
screen0	 equ $2000

 BEGIN_ZP
ptr		ds 2
tmp		ds 1
 END_ZP


 IFD LNX
	run	$200
 ELSE
	run	$200-3
	jmp	init
 ENDIF
Start::
	ldy	#$34
	ldx	#120
.co	txa
	sta	$fda0,x
	tya
	ror
	eor	$fd02
	tay
	and	#$1f
	adc	#$20
	sta	ptr+1
	tya
	ror
	eor	$fd02
	tay
	lda	#$f
	sta	(ptr),y
	dex
	bpl	.co

.loop
	lda	#$20
	sta	ptr+1
	tax
	ldy	#0
.fade
	lda	(ptr),y
	_IFNE
	   asl
	   sta (ptr),y
	   dey
	   lda (ptr),y
           rol
	   sta (ptr),y
	_ENDIF
	iny
	bne	.fade
	inc	ptr+1
	dex
	bpl	.fade

	bra	.loop

End:

size	set End-Start
free	set 64-size

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
