
	run $200
Start:
	ldx	#End-Start
.l	lda	$fcb2
.store	sta	$200,x
	inx
	bne	.l
	inc	.store+2
	dey
	bne	.l
End:
size	set End-Start
free	set 51-size

	IF free > 0
	REPT	free
	dc.b	0x42		; must be filled for Lynx ROM
	ENDR
	ENDIF
