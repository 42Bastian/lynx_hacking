***************
* MovingBar - Bouncing colored bar
* Size 32b - could be 30 with startup glitch
****************

	RUN	$200

 IFND	LNX
	;; Setup needed if loaded via BLL/Handy
	lda	#8
	sta	$fff9
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

	bra	Start
 ENDIF

	MACRO SKIP2
	dc.b $DC		;; NOP with 3 bytes/4 cycles
	ENDM

Start::
	;; $00 = 0 on entry

	lda	#10		; prevent start glitch
.loop
.1	cmp	$fd0a		; wait till line-counter is reached, C = 1
	bne	.1
.0
	dec	$fda0
	dec	$fdb0
	bne	.0
	adc	0		; C = 1 => increment if $00 == 0, else decrement
	cmp	#10
	beq	.nu
	cmp	#100
	bne	.loop
	dec	0		; $00 => $ff
	SKIP2
.nu
	stz	0
	bra	.loop


End:
size	set End-Start
free	set 32-size

	IF free > 0
	REPT	free
	dc.b	$42
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree"

	END
