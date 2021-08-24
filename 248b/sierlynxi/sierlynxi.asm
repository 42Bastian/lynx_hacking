***************
* 32Byte
****************

;;; ROM sets this address
screen0	 equ $2000

	run	$200

 IFND LNX
	;; Setup needed if loaded via BLL/Handy
	lda	#8
	sta	$fff9
	cli
	lda	#$20
	stz	$fd94
	sta	$fd95
	stz	$fd50
	ldy	#2
 ENDIF

Start::
	ldy	#31
.00	tya
	sta	$fda0,y
	dey
	bpl	.00
.0
	lda	#$20
	sta	1
	asl
	tay
.1
	lda	0
	and	1
	sta	(0)
	inc	0
	bne	.1
	inc	1
	dey
	bne	.1
	bra	.0
End:
size	set End-Start
free	set 32-size

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree"
