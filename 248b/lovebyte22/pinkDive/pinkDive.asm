***************
* pinkDive
* 125 bytes
****************
	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/if_while.mac>
	include <macros/suzy.mac>

 BEGIN_ZP
screen		ds 2
x		ds 1
y		ds 1
frame		ds 1
 END_ZP

 IFND LNX
	run	$200-3

	jmp	Init
 ELSE
	run	$200
 ENDIF

Start::
;;; pink scale palette
	clc
.pal
	  stz	$fda0,x
	  sta	$fdb0,x
	  inx
	  adc	#$11
	bcc	.pal

	lda	#USE_AKKU
	sta	SPRSYS

redo:
	lda	#$98|2
	sta	CONTRL_A
	sta	VOLUME_A
again:
	asl
	pha
	lda	#40
	bcs	.1
	asl
.1
	sta	FREQ_A
;;;------------------------------
;;; Swap screens
.swp
	lda	#$20
	sta	DISPADRH
	eor	#$40
	sta	.swp+1
	stz	screen
	sta	screen+1

	inc	frame

	ldy	#0

	lda	#51
	sta	y
.ly
	lda	#80
	sta	x
	clc
	adc	screen
	sta	screen
	_IFCS
	  inc	screen+1
	_ENDIF

.lx
	stz	MATHE_AKKU	; clear AKKU and AKKU+1
	lda	x
	jsr	square
	lda	y
	jsr	square
	lsr
	lsr
	sec
	sbc	frame
	and	#15
	sta	(screen),y
	iny
	_IFEQ
	  inc	screen+1
	_ENDIF
	dec	x
	bne	.lx
	dec	y
	bne	.ly
	pla
	beq	redo
	bra	again

	;; Y:A = A:X*A:X
square::
	clc
	adc	frame
	sta	MATHE_C
	;; Y:A = MATHE_C * A:X
mul::
	sta	MATHE_E+1

	WAITSUZY
	lda	MATHE_AKKU+1
	rts
;;;------------------------------

End:
size	set End-Start
free	set 128-size

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
