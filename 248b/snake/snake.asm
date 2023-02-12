***************
* Snake game
* 0 bytes free.
****************

	include <includes/hardware.inc>
	include <macros/help.mac>

 BEGIN_ZP
color	ds 1
tailptr	ds 1
x	ds 1
y	ds 1
dir	ds 1
tailcnt ds 1
taillen ds 1
ptr	ds 2
random	ds 1
 END_ZP

tailx	equ $500
taily	equ $600

;;; ROM sets this address
screen0	 equ $2000

 IFD LNX
	run	$200
 ELSE
	run	$200-3
	jmp	bll_init
 ENDIF

Start::
	stz	$fc92
	stz	MATHE_E
	dec	$fdaf
	lda	#$98|2
	sta	$fd25
	sta	$fd21
	sta	$fd24

	lda	#$10
	sta	x
	sta	y
	sta	dir
	sta	tailcnt
//->	sta	random

	lda	#250
	sta	taillen
	dec	tailptr
again:
	ldx	#2
vbl:
	jsr	vbl_key
	beq	.move
	sta	dir
.move
	dex
	bne	vbl

	stz	$fd20

	ldx	x
	ldy	y

	bbr7	dir,.noup
	dey
	bpl	.noup
	iny
.noup
	bbr6	dir,.nodown
	cpy	#50
	beq	.nodown
	iny
.nodown
	bbr5	dir,.noleft
	dex
	bpl	.noleft
	inx
.noleft
	bbr4	dir,.noright
	cpx	#79
	beq	.noright
	inx
.noright:
	stx	x
	sty	y
	phy
	phx
	dec	color
	jsr	plot_w_collide
	bne	.ko
	stz	color

	dec	tailcnt
	bne	.noinc

	lda	#$7f
	sta	$fd20

	smb2	tailcnt
	lda	taillen
	beq	.noinc
	dec	taillen
.noinc
	ldx	tailptr
	pla
	sta	tailx,x
	pla
	sta	taily,x
	dex
	stx	tailptr
	cpx	taillen
	bne	again

	dec	random
	bpl	.l0

	ora	$fd02
	and	#$f
	sta	random
	bra	.lx
.l0
	ldx	tailx+255
	ldy	taily+255
	jsr	plot_w_collide
.lx
	dex			; x = 255
.l1
	lda	tailx,x
	sta	tailx+1,x
	lda	taily,x
	sta	taily+1,x
	dex
	cpx	tailptr
	bne	.l1

	inc	tailptr
	jmp	again
.ko
	jsr	vbl_key
	bne	.ko
.wr
	dec	$fdb0
	jsr	vbl_key
	beq	.wr
	jmp	$ff80		;reset

vbl_key:
wait1	dec	$fdbf
	lda	$fd0a
	bne	wait1
wait2	lda	$fd0a
	beq	wait2

	lda	JOYPAD
	rts

plot_w_collide::
	sty	MATHE_C
	lda	#160
	sta	MATHE_E+1
.ws
	lsr
	bne	.ws

//->	clc
	txa
	adc	MATHE_A+1
	sta	ptr
	lda	MATHE_A+2
	adc	#$20
	sta	ptr+1
	lda	(ptr)
	tax
	lda	color
	sta	(ptr)
	ldy	#80
	sta	(ptr),y
	txa
	rts
End:
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
	;; Setup needed if loaded via BLL/Handy
	lda	#8
	sta	$fff9
	sei

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

	lda	#$fa
	sta	5
	stz	0

	ldy	#2
	lda	#0
	tax
	stz	$fc92
	jmp	$200
 ENDIF

	echo "Size:%dsize  Free:%dfree"
