* Mini loader *

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
free	set 50-size

	echo "Loader size %dsize"
