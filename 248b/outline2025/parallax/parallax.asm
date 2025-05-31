***************
* Paralax
* For Outline 2025
* Author: 42Bastian
* Size: 249 bytes
****************

	include <includes/hardware.inc>
	include <macros/help.mac>

 BEGIN_ZP
ptr		ds 2
fg_x		ds 1
 END_ZP


cls_SCB		EQU $110
cls_data	equ cls_SCB+5
cls_x		equ cls_SCB+7
cls_y		equ cls_SCB+9
cls_sizex	equ cls_SCB+11
cls_sizey	equ cls_SCB+13
cls_color	equ cls_SCB+15

	if NEXT_ZP > 255
	fail "ZP overrun"
	endif

 IFND LNX
	run	$200-3
	jmp	bll_init
 ELSE
	run	$200
 ENDIF
;;; ----------------------------------------
Start::
	ldy	#11
.mloop
	  ldx	SUZY_addr-1,y
	  lda	SUZY_data-1,y
	  sta	$fc00,x
	  ldx	scb_addr-1,y
	  lda	scb_data-1,y
	  sta	cls_SCB,x
	adc	#$40
	  sta	$fdb0,y
//->	lda	#0
	tya
//->	asl
	  sta	$fda0,y
	  dey
	bne .mloop
	txs			; make sure SP does not collide with SCBs

;;; Build sprite
.loop_line
	ldx	#7
.loop0:
	lda	#81		; line width
	pha			; evil: push also high byte of screen
	pha			; loop counter
	bra	skip
.loop
	pha
.cnt	eor	#25
	and	#2
	beq	skip
	lda	pattern,x
skip
smc	sta	$300,y
	iny
	bne	.ok1
	inc	smc+2
.ok1
	pla
	dec
	bne	.loop

	dex
	bpl	.loop0
	dec	.cnt+1
	bpl	.loop_line

	lda	#$98|$0
	sta	$fd25

//->	lda	#$50
//->	pha
;;------------------------------
main:
;;;------------------------------
;;; wait VBL
.v0
	ldx	$fd0a
	bne	.v0
;;;------------------------------
;;; Swap screens
	pla
	sta	$fd95
	eor	#$80
	sta	$fc09
	pha

	stz	cls_SCB		; => SPRCTL0_BACKGROUND_SHADOW
	stz	cls_color

	inc	fg_x
	lda	fg_x
	sta	$fd20
	and	#63
	pha
	pha
	lsr
	pha
	lsr			; quarter speed
	sta	$fdb4

	ldy	#$80		; half sized
	jsr	drawIt

	inc			; => SPRCTL0_BOUNDARY_SHADOW
	sta	cls_SCB

	pla			; half speed
	jsr	drawIt0		; normal size

	lda	#<cls_SCB+16
	jsr	draw_sprite

	pla
	jsr	drawIt0		; double size

	plx
	lda	64,x
	lsr
	sta	$fd24
	bra	main

	;; SCBs are a lot of zeros, so set only the other parts
scb_addr:
	;; outline SCB
	dc.b 16+0,16+9, 16+1,16+5,16+7,16+14,16+12,16+15,16+6
	;; background SCB
	dc.b 6,1

scb_data:
	;; outline SCB
	;; first 4 entries are also BR colors
	dc.b 4,44,$90,<plot_data,80-30+66,2,2,4,>plot_data
	;; background SCB
	dc.b 3,$90

	;; Writing low-byte in SUZY space clears highbyte!
SUZY_addr
	db $08,$04,$06,$83,$90,$92,$2a,$28

pattern:
	dc.b %00111000
	dc.b %01000100
	dc.b %10111010
	dc.b %11111110
	dc.b %10111010
	dc.b %01111100
	dc.b %00111000

SUZY_data
	db $00			; shared with pattern!
	db $40,$00,$f3,$01

drawIt0:
	ldy	#0		; A0 00 => fc92,fc2a !! (Suzy init data!)

drawIt::
	sta	cls_x
	sty	cls_sizex
	sty	cls_sizey
	stx	cls_sizex+1
	stx	cls_sizey+1
	lda	#<cls_SCB
	inx
	stx	cls_color
draw_sprite::
	sta	SCBNEXT
	lda	#>cls_SCB	; == 1 !!!
	sta	SCBNEXT+1
	STA	SPRGO		; start drawing
	STZ	SDONEACK
	STZ	CPUSLEEP
	rts			; evil!

	;; OUTLINE
plot_data:
	dc.b 5,%01100100,%10111010,%00111010,%01011100
	dc.b 5,%10010100,%10010010,%00010011,%01010000
	dc.b 5,%10010100,%10010010,%00010011,%01011000
	dc.b 5,%01100011,%00010011,%10111010,%11011100
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
	include "bll_init.inc"
 ENDIF
	echo "Size:%dsize  Free:%dfree"
