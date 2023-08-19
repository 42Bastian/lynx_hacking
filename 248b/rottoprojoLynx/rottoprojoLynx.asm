***************
* rottoprojolx - Port of rottoprojoXL to Lynx
****************

	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/if_while.mac>

;;; ROM sets this address
screen0	 equ $2000

 BEGIN_ZP
cnt		ds 1
ptr		ds 2
vertexX		ds 4
vertexY		ds 4
vertexZ		ds 4
vertexX_h	ds 4
vertexY_h	ds 4
vertexZ_h	ds 4

object		ds 1
rotatedVertex	ds 1
storage1	ds 1
x		ds 1
eor_val		ds 1
 END_ZP

CUBE_SIZE	equ 49
DISTANCE	equ 137
POINTS		equ 4
HIGH		equ POINTS

 IFND LNX
	run	$200
	jsr	init
 ELSE
	run	$200
 ENDIF
Start::
	ldx	#10+2
.mloop
	  lda	#CUBE_SIZE
	  sta	vertexX_h-1,x

	  ldy	SUZY_addr-3,x
	  lda	SUZY_data-3,x
	  sta	$fc00,y
	  dex
	bne .mloop

	lda #-CUBE_SIZE	;Inverted cube size
	sta vertexZ_h+1	;Vertex2 Z coordinate high-byte
	sta vertexY_h+2	;Vertex3 Y coordinate high-byte
	sta vertexY_h+3	;Vertex4 Y coordinate high-byte
	sta vertexZ_h+3	;Vertex4 Z coordinate high-byte
main::
	inc	cnt

	ldy	#<cls_SCB
	sty	SCBNEXT
	ldy	#>cls_SCB
	sty	SCBNEXT+1

	dey

	STY	SPRGO		; start drawing
	STZ	SDONEACK
.WAIT	STZ	CPUSLEEP
//->	bit	SPRSYS
//->	bne	.WAIT

	;; a == 0 !
vertex_loop:
	dec
	and	#7
	sta	object
	cmp	#4
	and	#3
	tax
	bcs	mirrors

	jsr	rs_y
	sty	vertexY,x
	sta	vertexY_h,x
	bit	cnt			; axis toggle
	bpl	skip
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
	adc	#DISTANCE+20
	lsr
	lsr
	sta	storage1
	lsr
	adc	storage1
	adc	#$26
	tay

	jsr	smulAY_X
	adc	#80
//->	lsr
	pha

	lda	vertexY_h,x
	jsr	smulAY
	adc	#53

	jsr	mulA_80
	adc	#$20
	sta	ptr+1
	lda	MATHE_A+1
	sta	ptr

//->	ply
	pla
	lsr
	tay
	lda	#$e
	bcs	.odd
	lda	#$e0
.odd
	sta	(ptr),y
	lda	object
	bne	vertex_loop
.v0
	lda	$fd0a
	beq	main
	bra	.v0
;;;------------------------------
rs_y:
	ldy	vertexY,x
	lda	vertexY_h,x
rs:
	stz	rotatedVertex
	_IFMI
	  dec rotatedVertex
	_ENDIF
	pha
	clc
	adc	vertexX,x
	sta	vertexX,x
	lda	vertexX_h,x
	adc	rotatedVertex
	sta	vertexX_h,x
	stz	rotatedVertex
	_IFMI
	  dec	rotatedVertex
	_ENDIF
	tya
	sec
	sbc	vertexX_h,x
	tay
	pla
	sbc	rotatedVertex
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
mulA_80:
	ldy	#80
mulAY::
	sta	MATHE_C		; A = C * E
mulY
	sty	MATHE_E+1
	dc.b	$5c,0,0		; nop with 8 cycles
	clc
//->.2	asl	SPRSYS
//->	bcs	.2
	lda	MATHE_A+2
	rts
;;;------------------------------
SUZY_addr
	db	$54,$09,$04,$06,$83,$92,$90

plot_data:
	dc.b	2,$10

SUZY_data
	db	$00,$20,$00,$00,$f3,$20

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


 IFND LNX
init::
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
	rts
 ENDIF
