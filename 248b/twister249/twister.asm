***************
* Twister249
* For Sillyventure WE 2023
* Author: 42Bastian
* Size: 249 bytes
****************

	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/if_while.mac>

 BEGIN_ZP
_plot_data 	ds 3
	ORG $f0
tmp		ds 2
div		ds 1
x1		ds 1
x2		ds 1
x3		ds 1
x4		ds 1
x1_		ds 1
off		ds 1
 END_ZP

tmp1		equ div

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
	bra	cont
	pha
	phx
	tsb	$fd80
	ldx	$fd0a
	lda	sinus+20,x
	sta	BLUERED0
	plx
	pla
	STZ	CPUSLEEP	; restart Suzy
	rti
cont:
	ldx	#8
	stx	$fff9		; enable vectors
	sty	$fffe		; y = 2 => $202
	sty	$ffff

	sty	_plot_data
.mloop
	  ldy	SUZY_addr,x
	  lda	SUZY_data,x
	  sta	$fc00,y
	  ldy	scb_init_addr,x
	  lda	scb_init_data,x
	  sta	cls_SCB,y
//->	  stz   tmp-1,x
	  dex
	bpl .mloop

	ldy	#128
	sty	_plot_data+1	; 1bpp
	tya
	tsb	$fd01		; enable interrupt
.singen
	inx
	txa
	txs			; save x (and set SP!)

	lsr			; only every second entry
	tax

	tya
	_IFEQ
	  dec	tmp1
	_ENDIF
	dey
	dey

	clc
	tya
	adc	tmp
	sta	tmp

	sta	$fda0,x		; set colors for twister (and some more)

	lda	tmp+1
	adc	tmp1
	sta	tmp+1

	sta	sinus,x
	sta	sinus+128,x
	eor	#$ff
	sta	sinus+64,x

	tsx
	cpx	#127

	bne	.singen

	;; y = $82 here

	cli			; enable interrupts
;;------------------------------
main:
;;;------------------------------
;;; Swap screens
	tya
	sty	$fd95
	eor	#$40
	tay
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
	pla			; get frame counter (first is rubbish)
	inc
	inc
	and	#127
	pha
	tax

//->	lda	sinus,x		; move twister (if only I find 6 more bytes)
//->	adc	#95
//->	sta	off

	lda	#90
	sta	plot_y
ly:
	dec	div
	_IFMI
	  lda	#2
	  sta	div
	  inx
	_ENDIF

	lda	sinus,x
	sta	x1
	sta	x1_		; repeat for loop
	eor	#$ff
	sta	x3

	lda	sinus+31,x
	sta	x2
	eor	#$ff
	sta	x4

	phx
	ldx	#4		; index and color
.0
	jsr	line_
	dex
	bne	.0
	plx

	dec	plot_y
	bne	ly
	bra	main

	;; Writing low-byte in SUZY space clears highbyte!
SUZY_addr
	db $08,$04,$07,$06,$2a,$28,$83,$92,$90
SUZY_data
	db $00,$00,$ff,$fa,$7f,$7f,$f3,$20
scb_init_data:
	db $01,SPRCTL1_LITERAL| SPRCTL1_DEPTH_SIZE_RELOAD,160,102
	db SPRCTL0_NORMAL,SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD,1
scb_init_addr
	db 0,1,12,14
	db 16+0,16+1,16+14

line_:
	stx	plot_color
	clc
	lda	x1-1,x
//->	adc	off
	adc	#80
	sta	plot_x
//->	sec
	lda	x1+1-1,x
	sbc	x1-1,x
	_IFPL
	  sta	size_x+1
	  lda	#<plot_SCB
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
.WAIT	STZ	CPUSLEEP
//->	bit	SPRSYS
//->	bne	.WAIT
	_ENDIF
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
bll_init:

	;; Setup needed if loaded via BLL/Handy
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
