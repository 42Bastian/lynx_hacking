***************
** LoveByte 2024 Countdown - 3 days left
** (c) 2023 42Bastiam
** 1 bytes free of 249
****************

	include <includes/hardware.inc>
	include <macros/help.mac>

;;; ROM sets this address
screen0	 equ $2000

ptr equ 4

plot_data	equ $fa00

 IFND LNX
	run	$200-3
	jmp	Init
 ELSE
	run	$200
 ENDIF
Start::
	bra	.cont
HBL:
	pha
	tsb	$fd80

	dex
	bpl	.x

	clc
	lda	$fdb0
	adc	#$10
	bcs	.y
	sta	$fdb0
	bra	.init
.y
	inc	$fdb0
.x
	lda	$fd0a
	bne	.exit

	stz	$fdb0
	dey			; VBL counter
.init
	ldx	#2
.exit
	STZ	CPUSLEEP	; restart SUZY
	pla
	rti

.cont:
	ldx	#$c
	stx	$fff9		; map vectors to RAM
	sty	$fffe		; IRQ vector $202
	sty	$ffff

	stz	$fdb1
;;; ----------------------------------------

	cli
.copy
;;; Build 2nd SCB
	  lda	plot_SCB+5,x
	  sta	plot_SCB1+5,x
;;; Init SUZY
	  ldy	SUZY_addr-2,x
	  lda	SUZY_data-2,x
          sta	$fc00,y
	  stz $fda0-1,x
	dex
	bpl	.copy
//->	ldy	#0
;;; ----------------------------------------
;;; Create pattern
	ldx	#%00001111
	stx	$fdb9
.loop
	lda	#4
	sta	(ptr),y
	iny
	txa
	sta	(ptr),y
	iny
	sta	(ptr),y
	iny
	iny
	beq	main

	tya
	and	#$f
	bne	.loop

	txa
	eor	#$ff
	tax
	bra	.loop
;;; ----------------------------------------
main::
	lda	#128
	sta	pd1		; init start of sprite data
	tsb	$fd01		; enable interrupt

.loop
	ldy	#<_3days_SCB
	sty	SCBNEXT
	ldy	#>_3days_SCB
	sty	SCBNEXT+1

	iny
.vbl_wait
	tya
	bne	.vbl_wait

	iny
	sty	SPRGO		; start drawing
	STZ	SDONEACK
	STZ	CPUSLEEP

	dec	_3days_y
	bpl	.1
	lsr	_3days_y
.1
	sec
	lda	pd1
	sbc	#4
	sta	pd1
	beq	main
	adc	#4*4-1
	sta	pd2
	bra	.loop
;;; ----------------------------------------
_3days_data:
	dc.b 5,%01100011,%10001100,%10010011,%10000000
	dc.b 5,%10010010,%01010010,%10010100,%00000000
	dc.b 5,%00100010,%01011110,%01100011,%00000000
	dc.b 5,%10010010,%01010010,%01000000,%10000000
	dc.b 5,%01100011,%10010010,%01000111,%00000000
	dc.b 5,0,0,0,0
_3days_SCB	dc.b 0
	dc.b SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD
	dc.b 0					;2
	dc.w plot_SCB				;3
	dc.w _3days_data				;5
_3days_x	dc.w 80-12*3				;7
_3days_y	dc.w 90					;9
	dc.w $300				;11
	dc.w $300				;13

	;; Writing low-byte in SUZY space clears highbyte!
SUZY_addr
	db $09			; also color index for _3DAYS sprite
	db $08,$04,$06,$28,$2a,$83,$92,$90
SUZY_data
	db $20,$00,$00,$00,$7f,$7f,$f3,$34

plot_SCB:
	db $01

//->	dc.b SPRCTL0_2_COL
	dc.b SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_STRETCH_RELOAD
	dc.b 0					;2
	dc.w plot_SCB1				;3
pd1	dc.w plot_data				;5
	dc.w 80					;7
	dc.w 59					;9
	dc.w $500				;11
	dc.w $10				;13
	dc.w $40
	dc.b $19				;15

plot_SCB1
	dc.b SPRCTL0_2_COL
	dc.b SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_STRETCH_RELOAD|SPRCTL1_DRAW_LEFT|SPRCTL1_PALETTE_NO_RELOAD
//->	dc.b 0					;2
//->	dc.w 0					;3
pd2	equ plot_SCB1+5
//->	dc.w plot_data+16			;5
//->	dc.w 80					;7
//->	dc.w 59					;9
//->	dc.w $500				;11
//->	dc.w $100				;13
//->	dc.w $80
End:
size	set End-Start
free	set 249-size

 IFND LNX
	;; Lynx rom clears to zero after boot loader!
	dc.b 0
 ENDIF

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF

 IFND LNX

Init:
	;; Setup needed if loaded via BLL
	lda	#8
	sta	$fff9
	sei

	stz	 $fc08
	stz	DISPADRL
	lda	#$20
	sta	DISPADRH

	ldx	#31
	lda	#$ff
.init
	sta	GREEN0,x
	dex
	bpl	.init
	stz	$fdaf
	stz	$fdbf

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
	stz	4
	stz	0

	ldy	#2
	lda	#0
	tax
	jmp	Start
 ENDIF
	echo "Size:%dsize  Free:%dfree"
