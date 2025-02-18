***************
* Mars
* For LoveByte 2025
* Author: 42Bastian
* Size: 512 bytes
****************

	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/if_while.mac>
	include <macros/suzy.mac>

LOADER_SIZE    equ $11

MAX_Z		EQU 200
SCALE_HEIGHT	equ 64
HORIZON		equ 90
HEIGHT		equ 60

 BEGIN_ZP
_plot_data 	ds 3
tmp		ds 2
tmp1		ds 2
frame		ds 1
z		ds 1
x		ds 1
dxz		ds 2
px		ds 1
px0		ds 1
py		ds 1
xl		ds 2
yl		ds 2
invz		ds 2
alien_pos	ds 1
alien_inc	ds 1
sinus		ds 128
y_buffer	ds 40
 END_ZP

cls_SCB		EQU $100
plot_SCB	EQU cls_SCB+16
alien_SCB	EQU cls_SCB+32

invz_lo		equ $1200
invz_hi		equ $1300

	if NEXT_ZP > 255
	fail "ZP overrun"
	endif

	echo "%HNEXT_ZP"
 IFND LNX
	run	$200-3
	jmp	bll_init
 ELSE
	run	$200+LOADER_SIZE
 ENDIF
;;; ----------------------------------------
Start::
	bra	skip_irq
irq::
	pha
	phx
	tsb	$fd80
	ldx	$fd0a
	lda	sinus+11,x
	sta	BLUERED0
	lsr
	sta	$FDA0
.exit
	plx
	pla
	STZ	CPUSLEEP	; restart Suzy
	rti
skip_irq::
	ldx	#12
	stx	$fff9
	inx
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

	ldy	#2
	sty	$ffff
	lda	#<irq
	sta	$fffe
	sty	_plot_data	; y = 2
	lda	#128
	tsb	$fd01
	tay
	sty	_plot_data+1	; 1bpp
.singen
	txa
	txs			; save x (and set SP!)

	lsr			; only every second entry
	tax

	dey
	dey

	clc
	tya
	_IFEQ
	  dec	tmp1+1
	_ENDIF
	adc	tmp
	sta	tmp

	lda	tmp+1
	adc	tmp1+1
	sta	tmp+1

	sta	$fda0,x

	sta	sinus,x
	eor	#$ff
	sta	sinus+64,x

	tsx
	inx
	bpl	.singen

	phy		;; y = $82 here

	stz	MATHE_A
	stz	MATHE_A+2

	ldy	#MAX_Z+28
	sty	MATHE_B
	lda	#SCALE_HEIGHT
	sta	MATHE_A+1
	ldx	#MAX_Z
create_reci:
	stz	MATHE_A+3
	WAITSUZY
	lda	MATHE_D
	sta	invz_lo-1,x
	lda	MATHE_D+1
	sta	invz_hi-1,x
	dec	MATHE_B
	dex
	bne	create_reci

	lda	#$98|5		;$5
	sta	$fd20
	sta	$fd25
	cli
;;------------------------------
main:

;;;------------------------------
;;; Swap screens
	pla
	sta	$fd95
	eor	#$40
	sta	$fc09
	pha
;;;------------------------------
;;; wait VBL
.v0
	lda	$fd0a
	bne	.v0

;;;------------------------------
//->	lda	#<cls_SCB
	jsr	draw_sprite

	lda	frame
	inc
	and	#127
	sta	frame
	tax

	clc
	lda	sinus,x
	tay
	adc	py
	sta	py

	tya
	asl
//->	clc
	adc	#80
	sta	alien_x

	ldx	#%00100100
	bit	#2
	beq	.move
	  ldx	#%10000001
.move
	stx	alien_leg+1
	lda	#32
	jsr	draw_sprite
;;;------------------------------

//->	stz	dxz
	sta	dxz+1		; dxz = 1*FP

	ldx	#40
	lda	#102
.clr
	sta	y_buffer,x
	dex
	bpl	.clr

	stz	yl
	lda	py
	sta	yl+1

	lda	px
	sta	px0

	stz	z
lz:
	ldx	z
	lda	invz_lo,x
	sta	invz
	lda	invz_hi,x
	sta	invz+1

	stz	xl
	lda	px0
	sta	xl+1


	lda	#39
lx:
	sta	x
	asl
	asl
	sta	plot_x

	lda	xl+1
	and	#127
	tay

//->	clc			; clear from above ASL
	lda	xl+1
	adc	yl+1
	and	#127
	tax
	lda	sinus,y
	adc	sinus,x
//->	_IFMI
//->	  lda	#0
//->	_ENDIF
	sta	tmp		; height and color
	eor	#$ff
	sec
	adc	#HEIGHT
	sta	MATHE_C
	lda	invz
	sta	MATHE_E
	lda	invz+1
	sta	MATHE_E+1

	NOP8
	clc
	lda	#102-HORIZON
	adc	MATHE_A+1
	bmi	.skip
	cmp	#101
	bcs	.skip
	tay
	ldx	x
	clc
	sbc	y_buffer,x
	_IFCC
	  eor	#$ff
	  _IFNE
	    sta	size_y+1
	    sty	plot_y
	    sty	y_buffer,x
	    lda tmp
	    lsr
	    and #$f
	    _IFEQ
	      lda #$f
	    _ENDIF
	    sta	plot_color
	    lda	#<plot_SCB
	    jsr	draw_sprite
	  _ENDIF
	_ENDIF

.skip
	sec
	lda	xl
	adc	dxz
	sta	xl
	lda	xl+1
	adc	dxz+1
	sta	xl+1

	lda	x
	dec
	bpl	lx

	clc
	lda	dxz
	adc	#16
	sta	dxz
	_IFCS
	  inc	dxz+1
	_ENDIF
	sec
	lda	yl
	sbc	dxz
	sta	yl
	lda	yl+1
	sbc	dxz+1
	sta	yl+1

	dec	px0

	dec	$fd24

	inc	z
	lbpl	lz
//->	lda	z
//->	cmp	#100
//->	lbne	lz

	dec	px


	jmp	main


	;; Writing low-byte in SUZY space clears highbyte!
SUZY_addr
	db $08,$04,$07,$06,$2a,$28,$83,$92,$90
SUZY_data
	db $00,$00,$ff,$fa,$7f,$7f,$f3,$20
scb_init_data:
	db $01,(SPRCTL1_LITERAL| SPRCTL1_DEPTH_SIZE_RELOAD),160,50
	db SPRCTL0_NORMAL, SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD, 4
	db SPRCTL0_NORMAL, SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD,<alien1,>alien1,2,2,12


alien1:
	dc.b 2,%01011010
	dc.b 2,%00111100
	dc.b 2,%01011010
	dc.b 3,%01111110,0
//->	dc.b 2,%00100100
	dc.b 2,%01000010
alien_leg:
	dc.b 3,%00100100,0
//->	dc.b 0

scb_init_addr
	db 0,1,12,14
	db 16+0,16+1,16+12
	db 32+0,32+1,32+5,32+6,32+12,32+14,32+15


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

alien_data	equ alien_SCB+5
alien_x		equ alien_SCB+7
alien_y		equ alien_x+2
alien_color 	equ alien_y+6
;;;------------------------------

 IFND LNX
	;; Lynx rom clears to zero after boot loader!
	dc.b 0
 ENDIF
size	set End-Start

free   set 512-LOADER_SIZE-size

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
