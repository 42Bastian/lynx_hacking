***************
* rasta - 128 byte intro
* 0 bytes free.
****************

	include <includes/hardware.inc>
	include <macros/help.mac>

 BEGIN_ZP
pos	ds 3
barsize	ds 3
pos_inc	ds 3
col	ds 3
 END_ZP

;;; ROM sets this address
screen0	 equ $2000

 IFD LNX
	run	$200
 ELSE
	run	$200-3
	jmp	bll_init
 ENDIF

Start::
	bra	cont
	lda	$fd81		; get pending interrupt
	sta	$fd80		; ack
	dec			; 1 => HBL, 8 => VBL
	bne	vbl

	ldx	col
	stx	$fda0		; green foreground
	bne	.xx
	lda	col+1		; blue middle
	beq	.xy
	asl
	asl
	asl
	asl
	dc.b $ae		; ldx nnnn
.xy
	lda	col+2
.xx
	sta	$fdb0

	ldx	#2
loop:
	lda	$fd0a		; line counter
	cmp	pos,x
	bcs	next
	lda	barsize,x
	sta	col,x
	dec	barsize,x
	bpl	next
	stz	col,x
next	dex
	bpl	loop
	rti

vbl:
	ldx	#2
loop_v
	lda	#15
	sta	barsize,x
	clc
	lda	pos,x
	adc	pos_inc,x
	sta	pos,x
	cmp	#15
	beq	top
	cmp	#101
	bne	next_v
top
	lda	pos_inc,x
	eor	#$fe		; 1 => -1 ; -1 => 1
	sta	pos_inc,x
next_v
	dex
	bpl	loop_v
	rti

cont:
	ldx	#8
	stx	$fff9		; map vector table
	sty	$fffe		; y = 2 => $202
	sty	$ffff
	lda	#$80
	tsb	$fd01		; enable HBL
	tsb	$fd09		; enable VBL
	cli
	lsr
	sta	pos
	sta	pos+1
	lsr
	sta	pos+2
	lda	#1
	sta	pos_inc
	sta	pos_inc+2
	lda	#-1
	sta	pos_inc+1
wait
	bra	wait

End:
 IFND LNX
	;; Lynx rom clears to zero after boot loader!
	dc.b 0
 ENDIF
size	set End-Start
free	set 128-size

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
	jmp	$200
 ENDIF

	echo "Size:%dsize  Free:%dfree"
