***************
* 8b "intro"
****************
EFFECT1 EQU $11

 IFND	LNX
	RUN	$1e0
	lda	#$20
	stz	$fd94
	sta	$fd95

	ldx	#0
.1	stz	$2000,x
	dex
	bne	.1
	jmp	$200
	ORG	$200
 ELSE
	RUN	$200
 ENDIF
Start::
	lda	$fd0a
	eor	$fd02
	asl
	asl
	asl
	sta	$fdb0
	bra	Start
End:
size	set End-Start
free 	set 16-size

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree"

	END

effect1:
	sbc	#$11
	asl
	sta	$fdb0


effect2:
	sbc	#$11
	lsr
	sta	$fdb0
