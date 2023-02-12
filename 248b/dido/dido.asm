***************
* WhiteCarpet
* 0 bytes free.
****************

	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/if_while.mac>

 BEGIN_ZP
frame	ds 1
x	ds 1
x1	ds 1
y	ds 1
 END_ZP

sine	equ $1000

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
	lda	sine+74,x
	sta	BLUERED0
	plx
	pla
	rti
cont:
	ldx	#8
	stx	$fff9
	sty	$fffe
	sty	$ffff

.mloop
	  ldy	SUZY_addr-1,x
	  lda	SUZY_data-1,x
	  sta	$fc00,y
	  dex
	bne .mloop

	lda	#$80
	pha
	tay
singen:
	dey
	dey
	tya
;;->	clc
	adc	#125
	lsr
	lsr
	lsr
	sta	sine,x
	eor	#$1f
	sta	sine+130,x
	tya
	inx
	clc
	adc	0
	sta	0
	bne	singen

	cli
;;------------------------------
main:
;;;------------------------------
;;; wait VBL
.v0
;;->	ldx	$fd0a
;;->	bne	.v0

;;;------------------------------
;;; Swap screens
.swp
	pla			; inital value $80
	tsb	$fd01
	sta	$fd95
	eor	#$40
	pha
	sta	$fc09
;;;------------------------------
	lda	#<cls_SCB
	jsr	draw_sprite

	lda	#22
lx:
	sta	x
	pha
	sta	MATHE_C+1
	jsr	get_sin
	lsr
	sta	MATHE_E+1
.2
	dec
	bne	.2		; wait for suzy

	lda	MATHE_A+2
	sta	x1
	lda	MATHE_A+3
	lsr
	ror	x1
	lsr
	ror	x1
	lsr
	ror	x1

	ldx	#30
lz:
	sec
	txa
	sbc	x
	adc	frame
	jsr	get_sin
	adc	x1
	sta	plot_y

	txa
	asl
	adc	x
;;->	clc
	adc	#80-60
	sta	plot_x

	lda	#<plot_SCB
	jsr	draw_sprite

	dex
	bne	lz

	pla
	dec
	bne	lx

//->	clc
	lda	frame
	adc	#4
	sta	frame
	bra	main

;;;------------------------------
;; Draw sprite
;; A - low byte of SCB
;; high byte common
draw_sprite::
	sta	SCBNEXT
	lda	#>cls_SCB
	sta	SCBNEXT+1
	dec
;;->	lda	#1
	STA	SPRGO		; start drawing
	STZ	SDONEACK
.WAIT	STZ	CPUSLEEP
	bit	SPRSYS
	bne	.WAIT
//->	rts

get_sin::
	asl
//->	clc
	adc	frame
	tay
	lda	sine,y
	rts

	;; Writing low-byte in SUZY space clears highbyte!
SUZY_addr
	db $04,$06,$28,$2a,$83,$92,$90
SUZY_data
	db $00,$00,$7f,$7f,$f3,$20
//->	,$01

cls_SCB::
	db $01						;0
	dc.b SPRCTL1_LITERAL| SPRCTL1_DEPTH_SIZE_RELOAD ;1
	dc.b 0						;2
	dc.w 0						;3
	dc.w plot_data					;5
	dc.w 0						;7
	dc.w 0						;9
	dc.w 160*$100					;11
	dc.w 102*$100					;13
//->	dc.b 0
plot_SCB:
	dc.b SPRCTL0_NORMAL
	dc.b SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD	;1
	dc.b 0						;2
	dc.w 0						;3
	dc.w plot_data					;5
plot_x	dc.w 0						;7
plot_y	dc.w 0						;9
	dc.w $100					;11
	dc.w $100					;13
plot_color:						;15
;;->	db	$0e
;;;------------------------------

plot_data:
	dc.b	2,$10
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
	jmp	$200
 ENDIF


	echo "Size:%dsize  Free:%dfree"
