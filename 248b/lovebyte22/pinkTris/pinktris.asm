***************
* PinkTris256
****************

	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/if_while.mac>

 BEGIN_ZP
dst	ds 2
src	ds 2
pf	ds 2
x	ds 1
y	ds 1
rot	ds 1
speed	ds 1
tmp	ds 2
collide	ds 1
xs	ds 1
ys	ds 1
rots	ds 1
button	ds 1
ptr	ds 2
 END_ZP

	run	$200

 IFND LNX
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
.clr2
	stz	$4000,x
	inx
	bne	.clr
	inc	.clr+2
	inc	.clr2+2
	dey
	bpl	.clr

	lda	#FLIP_JOYPAD
	sta	SPRSYS

	lda	#$fa
	sta	5
	stz	0

	stz	$fd94
	lda	#$20
	sta	$fd95

	ldx	#2
.v0
	lda	$fd0a
	bne	.v0
.v1
	lda	$fd0a
	beq	.v1
	dex
	bpl	.v0

	MOVEI dummy_irq,$fffe

	ldy	#2
	lda	#0
	tax

	bra	Start
dummy_irq:
	rti
 ENDIF
;;; ----------------------------------------------------------------------
Start::
	dec	$fdbf		; PINK :-)

	;; Setup playfield
	ldx	#24
	lda	#$33
	sta	pf+1
	ldy	#11
.pf0
	sta	(pf)
	sta	(pf),y
	inc	pf+1
	dex
	bpl	.pf0
.pf1
	sta	(pf),y
	dey
	bpl	.pf1

	;; Main loop
again::
	lda	#5
	sta	x
	lda	#$33
	sta	y
.check
	jsr	check
main
	jsr	draw_pf

	lda	$fcb0
	cmp	button
	beq	.down
	  sta	button
	  lsr
	  bcc	.norot
	  inc	rot
	  rmb2	rot
.norot
	  bbr4	button,.noleft
	  dec	x
.noleft
	  bbr5	button,.check
	  inc	x
.down
	dec	speed
	bpl	.check

	lda	#60
	sta	speed
	inc	y
	jsr	check
	bcc	main

settled::
//->	lda	y
//->	cmp	#$40
//->.gameover
//->	beq	.gameover

	lda	#$33+24		; start from bottom
	sta	pf+1
.y
	lda	#10
	tay
.x
	clc
	adc	(pf),y
	dey
	bne	.x
	cmp	#10
	beq	again		; empty line => end of scan
	tax
	bne	.not_full

	ldx	pf+1
.ymove
	stx	dst+1
	dex
	stx	src+1
.xmove
	lda	(src),y
	sta	(dst),y
	dey
	bne	.xmove
	cpx	#$33
	bne	.ymove
	SKIP2
.not_full
	dec	pf+1
	bra	.y

;;; ----------------------------------------
draw_pf::
;;; ----------------------------------------
	lda	#$33
	sta	pf+1
	asl
	sta	ptr
	sta	$fd95
	sta	ptr+1

	ldx	#26*2
.y
	ldy	#11
.x
	lda	(pf),y
	sta	(ptr),y
	dey
	bpl	.x
	txa
	lsr
	_IFCS
	  inc	pf+1
	_ENDIF
	clc
	lda	#80
	adc	ptr
	sta	ptr
	bcc	.2
	inc	ptr+1
.2
	dex
	bne	.y
	;; fall through
;;; ----------------------------------------
save_state::
;;; ----------------------------------------
	ldx	x
	stx	xs
	ldx	y
	stx	ys
	ldx	rot
	stx	rots
	bra	draw_brick
;;; ----------------------------------------
check::
;;; ----------------------------------------
	jsr	draw_brick
	lsr	collide
	bcc	_rts
	jsr	draw_brick

restore_state::
	lda	xs
	sta	x
	lda	ys
	sta	y
	lda	rots
	sta	rot
;;; fall through

;;;------------------------------
draw_brick::
;;;------------------------------
	ldx	rot
	lda	pattern_lo,x
	sta	tmp
	lda	pattern_hi,x

	stz	collide
	ldx	y
	stx	pf+1
.ly
	ldy	x
	ldx	#3
.lx
	asl	tmp
	rol
	pha
	bcc	.skip
	lda	(pf),y
	tsb	collide
	eor	#$ff
	sta	(pf),y
.skip
	pla
	iny
	dex
	bpl	.lx

	inc	pf+1
	tax
	bne	.ly
	sec
_rts	rts

pattern_hi:
	dc.b	%01000110, %00000111, %00000010, %00000100
pattern_lo:
	dc.b	%01000000, %00100000, %01100010, %11100000

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

	echo "Size:%dsize  Free:%dfree"
