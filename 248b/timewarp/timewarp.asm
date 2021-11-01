***************
* Parallax star field
* 14 bytes free.
****************

	include <includes/hardware.inc>
	include <macros/help.mac>

;;; ROM sets this address
screen0	 equ $2000

first		equ $00		; zero after ROM
cur_z		equ $01
frame		equ 2
rng_zp_high	equ $20		; non-zero after ROM (important!!)
rng_zp_low	equ $21

stars_x		equ $80
stars_x_low	equ $c0

stars_y		equ $4100
stars_z		equ $4200


	run	$200

 IFND LNX
;;; ------------------------------------------------------------------------
	;; Setup needed if loaded via BLL/Handy as .o file
	lda	#8
	sta	$fff9
	sei

	stz	$fd94
	lda	#$20
	sta	$fd95
	stz	$fd50
	stz	$fd20

	ldx	#15
.init
	txa
	sta	$fda0,x
	stz	$fdb0,x
	dex
	bpl	.init
	stz	$fdaf

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
	sta	$20
	stz	0

	ldy	#2
	lda	#0
	tax
 ENDIF

;;; ------------------------------------------------------------------------
Start::
	ldx	#8
.mloop
	  ldy	SUZY_addr-1,x
	  lda	SUZY_data-1,x
	  sta	$fc00,y
	  dex
	bne .mloop

;;;------------------------------
;;; grey scale palette
	clc
	txa
.pal
	  sta	$fda0,x
	  sta	$fdb0,x
	  inx
	  adc	#$11
	bcc	.pal

main::
;;;------------------------------
;;; Swap screens
.swp
	lda	#$20
	sta	$fd95
	eor	#$40
	sta	.swp+1
	sta	$fc09
;;;------------------------------
;;; wait VBL
.v0
	ldx	$fd0a
	bne	.v0
;;;------------------------------

	lda	#<cls_SCB
	jsr	draw_sprite

	stz	cur_z
.loop0
	ldx	#63
.loop
	lda	stars_x,x
	bne	.ok
;;;------------------------------
;;; new star
.col
;;;------------------------------
;; Random
;; (from codebase64)
	LDA rng_zp_high
	LSR
	LDA rng_zp_low
	ROR
	EOR rng_zp_high
	STA rng_zp_high ; high part of x ^= x << 7 done
	ROR		; A has now x >> 9 and high bit comes from low byte
	EOR rng_zp_low
	STA rng_zp_low	; x ^= x >> 9 and the low part of x ^= x << 7 done
	tay
	EOR rng_zp_high
	STA rng_zp_high ; x ^= x << 8 done
;;;------------------------------
	and	#15
	sta	stars_z,x
	;; y
	tya
	lsr
	cmp	#102
	bcs	.col
	sta	stars_y,x

	;; x
	lda	#176
	ldy	first		; at first place stars all over the screen
	bne	.x2		; later only right off the screen
.x
	eor	rng_zp_high

.x2
	sta	stars_x,x
	stz	stars_x_low,x
;;;------------------------------

.ok
	ldy	stars_z,x
	beq	.col
	cpy	cur_z
	bne	.next
	sta	plot_x
	lda	stars_y,x
	sta	plot_y
	sty	plot_color
.l
	lda	#<plot_SCB
	jsr	draw_sprite
	inc	plot_x
	lda	frame
	bpl	.sub
	dec	plot_color
	bpl	.l

	;; Speed depends on Z position
	;; x -= z*34/2456
.sub
	sec
	lda	stars_x_low,x
	sbc	#60
	sta	stars_x_low,x
	bcs	.sub1
	dec	stars_x,x
	beq	.sub2
.sub1
	dey
	bpl	.sub
.sub2
.next
	dex
	bpl	.loop
	inc	cur_z
	lda	cur_z
	cmp	#16
	bne	.loop0
	sta	first		; mark end of init phase
	inc	frame
	jmp	main

;;;------------------------------
;; Draw sprite
;; A - low byte of SCB
;; high byte common
draw_sprite::
	sta	SCBNEXT
	lda	#>plot_SCB
	sta	SCBNEXT+1
	lda	#1
	STA	SPRGO		; start drawing
	STZ	SDONEACK
.WAIT	STZ	CPUSLEEP
//->	bit	SPRSYS
//->	bne	.WAIT
	rts

;;;------------------------------
	;; Writing low-byte in SUZY space clears highbyte!
SUZY_addr
	db $08,$04,$06,$28,$2a,$83,$92,$90
SUZY_data
	db $00,$10,$00,$7f,$7f,$f3,$20
//->	,$01

cls_SCB::
	db $01						;0
	dc.b SPRCTL1_LITERAL| SPRCTL1_DEPTH_SIZE_RELOAD ;1
	dc.b 0						;2
	dc.w 0						;3
	dc.w plot_data					;5
	dc.w 16					;7
	dc.w 0						;9
	dc.w 160*$100					;11
	dc.w 102*$100					;13
	dc.b 0

plot_SCB:
	dc.b SPRCTL0_NORMAL|SPRCTL0_16_COL
	dc.b SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD	;1
	dc.b $10					;2
	dc.w 0						;3
	dc.w plot_data					;5
plot_x	dc.w 80						;7
plot_y	dc.w 15						;9
	dc.w $100					;11
	dc.w $100					;13
plot_color:						;15
	db	$0f

plot_data:
	dc.b	2,$10

 IFND LNX
	;; Lynx rom clears to zero after boot loader!
	dc.b 0
 ENDIF
End:
size	set End-Start
free	set 249-size

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree"
