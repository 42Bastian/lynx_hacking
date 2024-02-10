**************
* lynxYarc512
*
****************

	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/if_while.mac>
	include <macros/suzy.mac>

LOADER_SIZE	equ $11
FILLER		EQU $43

CUBE_SIZE	equ 55
DISTANCE	equ 137

 BEGIN_ZP
_plot_data	ds 3
	;; line
x0		ds 1
x1		ds 1
y0		ds 1
y1		ds 1
temp		ds 1

	;; cube
object		ds 1
signExtend	ds 1
storage1	ds 1
x		ds 1
eor_val		ds 1
cnt		ds 1
vertexX		ds 4
vertexY		ds 4
vertexZ		ds 4
vertexX_h	ds 4
vertexY_h	ds 4
vertexZ_h	ds 4
screenx		ds 8*2
screeny		ds 8*2

	;;
p0x		ds 1
p1x		ds 1
p2x		ds 1
p3x		ds 1
p4x		ds 1

p0y		ds 1
p1y		ds 1
p2y		ds 1
p3y		ds 1
p4y		ds 1
 END_ZP

dl_scb	equ $100

dl_scb_x	equ dl_scb+7
dl_scb_y	equ dl_scb+9
dl_scb_xsize	equ dl_scb+11
dl_scb_ysize	equ dl_scb+13
dl_scb_stretch	equ dl_scb+15
dl_scb_tilt	equ dl_scb+17
dl_scb_color	equ dl_scb+19

cls_scb		equ dl_scb_color
cls_scb_xsize	equ cls_scb+11
cls_scb_ysize	equ cls_scb+13
cls_scb_color	equ cls_scb+15

 IFND LNX
	run	$200-3
	jmp	init
 ELSE
	run	$200+LOADER_SIZE
 ENDIF

	;; X = Y = 0 after loader
	;; A == FILLER
Start::
	ldx	#11-1
.vloop
	  ldy	SUZY_addr,x
	  lda	SUZY_data,x
          sta	$fc00,y
	  lda	#CUBE_SIZE
	  sta	vertexX_h,x
	  dex
	bpl	.vloop
	txs
	stx	$fda1

	lda	#-CUBE_SIZE	;Inverted cube size
	sta	$fdb1
	sta	vertexZ_h+1	;Vertex2 Z coordinate high-byte
	sta	vertexY_h+2	;Vertex3 Y coordinate high-byte
	sta	vertexY_h+3	;Vertex4 Y coordinate high-byte
	sta	vertexZ_h+3	;Vertex4 Z coordinate high-byte

	;; build SCBs in stack page
	lda	#$10
	pha
	sta	1		; sprite data
	stz	2		; sprite data
	lda	#SPRCTL1_LITERAL|SPRCTL1_DEPTH_ALL_RELOAD
	sta	dl_scb+1
	lda	#2
	sta	0		; sprite data
	dec			; => SPRCTL0_BACKGROUND_NON_COLLIDABLE
	sta	cls_scb
	lda	#SPRCTL1_LITERAL| SPRCTL1_DEPTH_SIZE_RELOAD
	sta	cls_scb+1
	sta	cls_scb_xsize+1
	sta	cls_scb_ysize+1
main::
//->	stz	$fda0
;;;------------------------------
;;; wait VBL
.v0
	lda	$fd0a
	bne	.v0

	pla
	sta	$fd95
	eor	#$80
	sta	$fc09
	pha
//->	dec	$fda0
;;;------------------------------
	lda	#<cls_scb
	jsr	draw_sprite

._2nd
	inc	cnt
	lda	#15		; 7 => one inc per frame, 15 => two
vertex_loop:
	sta	object
	and	#3
	tax
	bbs2	object,mirrors

	jsr	rs_y
	sty	vertexY,x
	sta	vertexY_h,x
	bbr7	cnt,skip			; axis toggle

	; Rotate on y-axis
	ldy	vertexZ,x
	lda	vertexZ_h,x
	jsr	rs
	sty	vertexZ,x
	sta	vertexZ_h,x
skip
	lda	#0
	SKIP2
mirrors:
	lda	#$ff

	sta	eor_val
	eor	vertexZ_h,x
	adc	#DISTANCE
	lsr
	adc	#$39
	tay

	jsr	smulAY_X
	adc	#80
	pha

	lda	vertexY_h,x
	jsr	smulAY
	adc	#51

	ldx	object
	sta	screeny,x
	pla
	sta	screenx,x

	dex
	txa
	bpl	vertex_loop
//->	bbs0	cnt,._2nd	; run twice for better speed

drawit:
;;;------------------------------

	inx
	SKIP1
.skip
	plx
	ldy	#3
.x	lda	faces,x
	bmi	main
	phx
	tax
	lda	screenx,x
	sta	p0x,y
	sta	p4x
	lda	screeny,x
	sta	p0y,y
	sta	p4y
	plx
	inx
	dey
	bpl	.x
	phx
//->	brk	#1
	jsr	hidden
	bmi	.skip
	ldx	#4
.loop_rect
	ldy	#1
.lr1	lda	p0x,x
	sta	x0,y
	lda	p0y,x
	sta	y0,y
	dex
	dey
	bpl	.lr1
	jsr	DrawLine
	inx
	bne	.loop_rect
	bra	.skip

;;;------------------------------
	;; Writing low-byte in SUZY space clears highbyte!
SUZY_addr
	db $54,$08,$04,$06,$28,$2a,$83,$92,$90
SUZY_data
	db $00,$00,$00,$00,$7f,$7f,$f3,$60
//->	,$1

faces:
	dc.b 5,7,0,2
	dc.b 4,5,2,3
	dc.b 0,1,3,2
	dc.b 6,7,5,4

;;; --------------------
;;  int res=0;
;;  res += p0.x*p1.y;
;;  res += p1.x*p2.y;
;;  res += p2.x*p0.y;
;;  int res2 = 0;
;;  res2 += p0.y*p1.x;
;;  res2 += p1.y*p2.x;
;;  res2 += p2.y*p0.x;
;;  if ( res-res2 < 0  ) return;

hidden::

	jsr	init_math
.x2
	lda	p0y,x
	ldy	p1x,x
	cpx	#2
	bne	.x2a
	ldy	p0x
.x2a
	jsr	_mulAY
	bpl	.x2
	sta	temp
	sty	temp+1

	jsr	init_math
.x1
	lda	p0x,x
	ldy	p1y,x
	cpx	#2
	bne	.x1a
	ldy	p0y
.x1a
	jsr	_mulAY
	bpl	.x1
	sec
	sbc	temp
	tya
//->	sbc	temp+1
//->	rts
init_math:
	ldx	#2
	stz	MATHE_AKKU
	stz	MATHE_AKKU+2
	sbc	temp+1
	rts

_mulAY:
	jsr	mulAY
	lda	MATHE_AKKU+1
	ldy	MATHE_AKKU+2
	dex
	rts

hidden_size equ *-hidden

rs_y::
	ldy	vertexY,x
	lda	vertexY_h,x
rs:
	stz	signExtend
	_IFMI
	  dec signExtend
	_ENDIF
	pha
	clc
	adc	vertexX,x
	sta	vertexX,x
	lda	vertexX_h,x
	adc	signExtend
	sta	vertexX_h,x
	stz	signExtend
	_IFMI
	  dec	signExtend
	_ENDIF
	tya
	sec
	sbc	vertexX_h,x
	tay
	pla
	sbc	signExtend
	rts

smulAY_X::
	lda	vertexX_h,x
;;;------------------------------
smulAY::
	eor	eor_val
	bpl	mulAY
	eor	#$ff
	jsr	mulAY
	eor	#$ff
	rts
;;;------------------------------
mulAY::
	sta	MATHE_C		; A = C * E
	sty	MATHE_E+1
	NOP8
	clc
	lda	MATHE_A+2
	rts

	include "line.inc"


End:
size	set End-Start
free	set 512-LOADER_SIZE-size

	IF free > 0
	REPT	free
	dc.b	FILLER
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree"

 IFND LNX
init::
	;; Setup needed if loaded via BLL/Handy
	lda	#8
	sta	$fff9
	sei
	lda	#0
	sta	$fd94
	lda	#$20
	sta	$fd95
	stz	$fd50
	ldy	#2
	stz	0
	lda	#$e
	sta	$fdae
	ldx	#15
.init
	txa
	sta	$fda0,x
	stz	$fdb0,x
	dex
	bpl	.init

	ldx	#0
.stack	stz	$100,x
	dex
	bne	.stack

	ldy	#8192/256
.clr
	stz	$2000,x
	inx
	bne	.clr
	inc	.clr+2
	dey
	bne	.clr
	ldx	#5
.clr1	stz	0,x
	dex
	bpl	.clr1
	txs
	inx
	ldy	#0
	lda	#$fa
	sta	4+1
	stz	$fd20
	sta	$20
	lda	#0
	jmp	Start
 ENDIF

 echo "hidden %Hhidden %dhidden_size"
