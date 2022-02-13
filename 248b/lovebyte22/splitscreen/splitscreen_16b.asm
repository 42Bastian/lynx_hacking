***************
* 16b "intro"
****************
EFFECT1 EQU $11

 IFND	LNX
	RUN	$1e0
	ldx	#0
	ldy	#$20
.1	stz	$2000,x
	dex
	bne	.1
	inc	.1+2
	dey
	bne	.1
	stz $fda0
	stz $fdb0
	jmp	$200
	ORG	$200
 ELSE
	RUN	$200
 ENDIF
Start::
	stz	$fdb0

.2	dec	$fdb0
	nop
	lda	$fd0a
	cmp	#40
	bcc	.2

	bra	Start
End:
size	set End-Start
free	set 16-size

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree"

	END
