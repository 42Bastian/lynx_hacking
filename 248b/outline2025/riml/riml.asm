****************
** Raster ist mein Laster
** 249b Intro for Outline 2025
** Author: 42Bastian
****************

	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/if_while.mac>

 BEGIN_ZP
_plot_data 	ds 3
tmp		ds 2
frame		ds 1
off		ds 1
 END_ZP

tmp1		equ frame

cls_SCB		EQU $100
plot_SCB	EQU cls_SCB+16

sinus:	equ $21

 IFND LNX
	run	$200-3
	jmp	bll_init
 ELSE
	run	$200
 ENDIF
;;; ----------------------------------------
Start::
	bra	skip_irq
irq::
	pha
	phx
	tsb	$fd80
	lda	frame
//->	asl
	and	#127
	tax
	lda	sinus,x
	sbc	$fd0a
	and	#31
	tax
	lda	$fda0,x
	sta	$fda0
.exit
	plx
	pla
	STZ	CPUSLEEP	; restart Suzy
	rti
skip_irq::
	ldx	#12
	stx	$fff9
	sty	_plot_data
	sty	$ffff
	sty	$fffe

.mloop
	  ldy	SUZY_addr,x
	  lda	SUZY_data,x
	  sta	$fc00,y
	  ldy	scb_init_addr,x
	  lda	scb_init_data,x
	  sta	cls_SCB,y
	  stz   tmp-1,x
	  dex
	bpl .mloop

	ldx	#7
	ldy	#0
.mloop2
	txa
	sta	$fda0,x
	sta	$fda8,y
	asl
	sta	$fdb0,x
	sta	$fdb8,y
	iny
	dex
	bpl	.mloop2

	lda	#128
	tsb	$fd01
	tay
	sty	_plot_data+1	; 1bpp

.singen
	inx
	txa
	txs			; save x (and set SP!)

	lsr			; only every second entry
	tax

	tya
	_IFEQ
	  dec	tmp1+1
	_ENDIF
	dey
	dey

	clc
	tya
	adc	tmp
	sta	tmp

	lda	tmp+1
	adc	tmp1+1
	sta	tmp+1

	sta	sinus,x
	eor	#$ff
	sta	sinus+64,x

	tsx
	bpl	.singen
	cli
	;; y = $82 here
	phy
;;------------------------------
main:
	inc	frame
;;;------------------------------
;;; Swap screens
	pla
	sta	$fd95
	eor	#$40
	pha
	sta	$fc09
;;;------------------------------
;;; wait VBL
.v0
	lda	$fd0a
	bne	.v0

;;;------------------------------
//->	lda	#<cls_SCB
	jsr	draw_sprite
;;;------------------------------
	stz	plot_SCB+SCB_Y
	ldy	#50
.loop
	inc	plot_SCB+SCB_Y

	tya
	adc	frame
	asl
	and	#127
	tax
	lda	sinus,x
	adc	#80
	sta	plot_SCB+SCB_X

	tya
	asl
	sta	plot_SCB+SCB_Y_SIZE+1

	tya
	and	#15
	bne	.1
	inc
.1
	sta	plot_SCB+SCB_SZ_COLOR

	lda	#16
	jsr	draw_sprite
	dey
	bne	.loop
	bra	main

	;; Writing low-byte in SUZY space clears highbyte!
SUZY_addr
	db $08,$04,$06,$83,$92,$90,$2a,$28
SUZY_data
	db $00,$00,$00,$f3,$20
scb_init_data:
	db $01,SPRCTL1_LITERAL| SPRCTL1_DEPTH_SIZE_RELOAD,160,102
	db 4,SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD,2
scb_init_addr
	db 0,1,SCB_X_SIZE+1,SCB_Y_SIZE+1
	db 16+0,16+1,16+SCB_X_SIZE+1

;;;------------------------------
;; Draw sprite
;; A - low byte of SCB
;; high byte common
draw_sprite::
	sta	SCBNEXT
	lda	#>plot_SCB	; == 1 !!!
	sta	SCBNEXT+1
	STA	SPRGO		; start drawing
	STZ	SDONEACK
	STZ	CPUSLEEP
	rts
End:

plot_x 		equ plot_SCB+7
plot_y		equ plot_x+2
size_x		equ plot_y+2
size_y		equ size_x+2
plot_color 	equ size_y+2

;;;------------------------------

 IFND LNX
	;; Lynx rom clears to zero after boot loader!
	dc.b 0
 ENDIF
size	set End-Start
free	set 249-size

	IF free > 0
	REPT	free
	dc.b	42
	ENDR
	ENDIF
;;; ----------------------------------------------------------------------
 IFND LNX
	include "bll_init.inc"
 ENDIF
	echo "Size:%dsize  Free:%dfree"
