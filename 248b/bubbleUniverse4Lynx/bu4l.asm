***************
* BubbleUniverse4Lynx - bu4l
* Author: 42Bastian
* Size: 246/249 bytes
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
	ldx	#9
.mloop
	  ldy	SUZY_addr,x
	  lda	SUZY_data,x
	  sta	$fc00,y
	  dex
	bpl .mloop
	;; y = $54
	sty	swp
	stx	$fdbe
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
	pha
	adc #23
	sta sinus,x
	sta sinus+128,x
	eor #$ff
	adc #53
	sta sinus+64,x
	pla
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
;;; --------------------
main::
//->	stz	$fdb0
;;;------------------------------
;;; wait VBL
.v0
	lda	$fd0a
	bne	.v0
;;;------------------------------
;;; Swap screens
	lda	swp
	sta	$fd95
	eor	#$40
	sta	swp
	sta	$fc09

//->	dec	$fdb0

	ldx	#<cls_SCB
	stx	SCBNEXT
	ldx	#>cls_SCB
	stx	SCBNEXT+1

	dex

	STX	SPRGO		; start drawing
	STZ	SDONEACK
.WAIT	STZ	CPUSLEEP
//->	bit	SPRSYS
//->	bne	.WAIT

	lda	#24
	sta	i
loopi:
	lda	i
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

//->	clc
	lda	i0
	adc	frame
	adc	u
	tay

//->	clc
	lda	i1
	adc	v

	stz	u
	stz	v
	jsr	si_co

	tya
	jsr	si_co
;;;------------------------------
plot:
	jsr	mulA_80
	sec
	adc	swp
	sta	ptr+1
	lda	MATHE_A+1
	sta	ptr

	lda	u
	lsr
	tay
	lda	#$e
	bcs	.odd
	lda	#$e0
.odd
	ora	(ptr),y
	sta	(ptr),y
;;;------------------------------
	dec	j
	bne	loopj

	dec	i
	bne	loopi
	inc	frame
	lbra	main

si_co:
	ldx	#191		; magic value to convert degree to radians
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
;;;------------------------------
mulA_80:
	ldx	#80
mulAX::
	sta	MATHE_C		; A = C * E
	stx	MATHE_E+1
	dc.b	$5c,0,0		; nop with 8 cycles
	lda	MATHE_A+2
	rts

SUZY_addr
	db	$54,$04,$06,$83,$92,$90

plot_data:
	dc.b	2,$10

SUZY_data
	db	$00,$00,$00,$f3,$20

cls_SCB::
	db $01						;0
	dc.b SPRCTL1_LITERAL| SPRCTL1_DEPTH_SIZE_RELOAD ;1
	dc.b 0						;2
	dc.w 0						;3
	dc.w plot_data					;5
	dc.w 0						;7
	dc.w 0						;9
	dc.w 160*$100					;11
	dc.w 103*$100					;13
//->	dc.b 0
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
