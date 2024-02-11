***************
* BubbleUniverse4Lynx - bu4l
* Author: 42Bastian
* Size: 249 bytes
****************

	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/if_while.mac>

 BEGIN_ZP
i		ds 1
j		ds 1
i0		ds 1
i1		ds 1
u		ds 1
v		ds 1
frame		ds 1
ptr		ds 2
swp		ds 1
tmp		ds 1
 END_ZP

sinus:		equ $40

 IFND LNX
	run	$200-3
	jmp	bll_init
 ELSE
	run	$200
 ENDIF
;;; ----------------------------------------
Start::
	bra	cont
	pha
	phx
	tsb	$fd80
	ldx	$fd0a
	lda	sinus+20,x
	lsr
	sta	BLUERED0
	plx
	pla
	rti
cont:
	ldx	#8
	stx	$fff9		; enable vectors
	sty	$fffe		; y = 2 => $202
	sty	$ffff

	stz	SPRSYS
	stz	MATHE_E
;;; --------------------
;;; sine table generator (by serato^fig)
	lda #57
	sta v
	lda #39
	ldx #63
.1	sta u
	lsr
	lsr
	lsr
	tay
	adc #23
	sta sinus,x
	sta sinus+128,x
	eor #$ff
	adc #53
	sta sinus+64,x
	txa
	sta $fda0,x
	tya
	lsr
	lsr
	lsr
	adc v
	sta v
	lsr
	lsr
	lsr
	sbc u
	adc #240
	eor #$ff
	dex
	bpl .1

	lda	#$80
	tsb	$fd01
	cli
;;; --------------------
main::
	lda	#$21
	sta	ptr+1
	stz	ptr
	tax
	ldy	#0
.fade
	lda	(ptr),y
	_IFNE
	  sta	tmp
	  and	#$f0
	  _IFNE
            trb	tmp
  	    sec
	    sbc	#$10
	  _ENDIF
	  dec	tmp
	  _IFPL
	    ora tmp
	  _ENDIF
	  sta (ptr),y
	_ENDIF
	iny
	bne	.fade
	inc	ptr+1
	dex
	bpl	.fade

	lda	#24
loopi:
	sta	i
	asl
	asl
	asl
	sta	i0
	asl
	asl
	sta	i1
	lda	#24
	sta	j
loopj:

	clc
	lda	i0
	adc	frame
//->	clc
	adc	u
	ldy	v
	stz	u
	stz	v
	jsr	si_co

//->	clc
	tya
	adc	i1
	jsr	si_co
;;;------------------------------
plot:
	sbc	#$a
	ldx	#80
	jsr	mulAX

	sec
	adc	#$20
	sta	ptr+1
	lda	MATHE_A+1
	sta	ptr

	lda	u
	lsr
	tay
	lda	#$f
	bcs	.odd
	lda	#$f0
.odd
	ora	(ptr),y
	sta	(ptr),y
;;;------------------------------
	dec	j
	bne	loopj

	lda	i
	dec
	bne	loopi
	inc	frame
	bra	main

si_co:
	ldx	#191
	jsr	mulAX
	and	#127

	tax
	lda	sinus+32,x
	adc	u
	sta	u
	lda	sinus,x
	adc	v
	sta	v
	rts
mulAX:
	sta	MATHE_C		; A = C * E
	stx	MATHE_E+1
	NOP8
	lda	MATHE_A+2
	rts
End:
;;;------------------------------

 IFND LNX
	;; Lynx rom clears to zero after boot loader!
	dc.b 0
 ENDIF
size	set End-Start
free	set 249-size

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF
;;; ----------------------------------------------------------------------
 IFND LNX
bll_init:

	;; Setup needed if loaded via BLL/Felix
	lda	#8
	sta	$fff9
	sei

	stz	 $fc08
	stz	DISPADRL
	lda	#$20
	sta	DISPADRH

	ldx	#15
	lda	#$ff
.init
	sta	GREEN0,x
	sta	BLUERED0,x
	sec
	sbc	#$11
	dex
	bpl	.init
	stz	$fdaf

	lda	#$ff
	sta	$fc28
	sta	$fc29
	sta	$fc2a
	sta	$fc2b
	lda	#16
	sta	$fc08

	inx
	ldy	#8192/256
.clr
	stz	$2000,x
	inx
	bne	.clr
	inc	.clr+2
	dey
	bpl	.clr

	ldx	#0
.clrsp
	stz	$100,x
	dex
	bne	.clrsp

	lda	#$fa
	sta	5
	stz	0

	ldy	#2
	lda	#0
	tax
	jmp	$200
 ENDIF
	echo "Size:%dsize  Free:%dfree"
