***************
* XOR Scroll
* 62 bytes
****************
	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/if_while.mac>

 BEGIN_ZP
ptr	ds 2
 END_ZP


 IFND LNX
	run	$200-3

	jmp	Init
 ELSE
	run	$200
 ENDIF

Start::
	dec	$fdbf
	ldx	#$20
	tay
.init
	stx	ptr+1
	tya
	lsr
	eor	ptr+1
	lsr
	and	#3
	dec
	sta	(ptr),y
	dey
	bne	.init
	inx
	bpl	.init

.again
	lda	#0
	ldx	#$20
.loop
.v0
	ldy	$fd0a
	sty	$fdb0
	sty	$fda1
	bne	.v0
.v1
	cpy	$fd0a
	beq	.v1

	sta	$fd94
	stx	$fd95

	clc
	adc	#80
	_IFCS
	  inx
	_ENDIF
	cpx	#$28+16+8
	bne	.loop
	bra	.again
.end
End:
size	set End-Start
free	set 64-size

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF
 IFND LNX
Init::
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

	MOVEI dummy_irq,$fffe

	ldy	#2
	lda	#0
	tax

	jmp	Start
dummy_irq:
	rti
 ENDIF

	echo "Size:%dsize  Free:%dfree"

	END
