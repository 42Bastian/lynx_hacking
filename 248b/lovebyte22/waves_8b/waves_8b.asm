***************
* 8b "intro"
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
	adc	#$78
	asl
	sta	$fdb0
	bra	Start
End:
size	set End-Start
free 	set 8-size

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
