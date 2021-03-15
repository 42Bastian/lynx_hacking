***************
** LYnxLOveBYte 256 Intro
** (c) 2021 42Bastiam
** 1 byte free of 249
****************

	include <includes/hardware.inc>
	include <macros/help.mac>
;;; ROM sets this address
screen0	 equ $2000

 BEGIN_ZP
vbl	ds 1
 END_ZP

ptr equ 4


plot_data	equ $fa00

	run	$200

 IFND LNX
	;; Setup needed if loaded via BLL/Handy
	lda	#8
	sta	$fff9
	sei
	lda	#$20
	stz	$fd94
	sta	$fd95
	stz	$fd50
	ldy	#2
	stz	vbl
	lda	#$e
	sta	$fdae
	ldx	#32
	lda	#$ff
.init
	sta	$fda0-1,x
	dex
	bne	.init
	stz	$fda0
	ldy	#8192/256
.clr
	stz	$2000,x
	inx
	bne	.clr
	inc	.clr+2
	dey
	bne	.clr
	stz	ptr
	lda	#$fa
	sta	ptr+1
 ENDIF

Start::
	ldx #$c
	stx $fff9
	stx $fda9
	stz $fdb9
	stx $fdb1
;;; ----------------------------------------
;;; Build 2nd SCB
.copy
	lda	plot_SCB+4,x
	sta	plot_SCB1+4,x
	dex
	bne .copy

;;; ----------------------------------------
;;; Init SUZY
	ldy	#9-1
.mloop
	  ldx	SUZY_addr,y
	  lda	SUZY_data,y
          sta	$fc00,x
          dey
        bpl .mloop

;;; ----------------------------------------
;;; Create pattern
	ldx	#%11001100
	iny
.loop
	lda	#4
	sta	(ptr),y
	iny
	txa
	sta	(ptr),y

	iny
//->	sta	(ptr),y
	iny
//->	lda	#0		; memory is zero'ed by Bootrom
//->	sta	(ptr),y
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
	ldx	#<hbl
	stx	$fffe
	ldx	#>hbl
	stx	$ffff
	;; ldx #2 == >hbl !
	cli
.again:
	lda	#128
	tsb	$fd01
	sta	pd1
.loop
	lda	#<bll_SCB
	sta	SCBNEXT
	lda	#>bll_SCB
	sta	SCBNEXT+1

//->	lda	#3
	inc
	sta	vbl
.v1
	lda	vbl
	bne	.v1

	inc
	sta	SPRGO		; start drawing

	STZ	SDONEACK
.WAIT	STZ	CPUSLEEP
	bit	SPRSYS
	bne	.WAIT

	dec	bll_y
	sec
	lda	pd1
	sbc	#4
	sta	pd1
	beq	.again
	adc	#4*4-1
	sta	pd2
	bra	.loop

;;; ----------------------------------------
hbl::
	pha
	lda	#$1
	sta	$fd80

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
	dec	vbl
.init
	ldx	#2
.exit
	pla
	rti

;;;------------------------------
bll_data:
	// 42BS
	dc.b 3,%10000100, %11000110
	dc.b 3,%10101010, %10101000
	dc.b 3,%11100010, %11000100
	dc.b 3,%00100100, %10100010
	dc.b 3,%00101110, %11001100
	// BLL
//->	dc.b 3,%11100100, %00100000
//->	dc.b 3,%10010100, %00100000
//->	dc.b 3,%11100100, %00100000
//->	dc.b 3,%10010100, %00100000
//->	dc.b 3,%11100111, %10111100
	dc.b 3,0,0
bll_SCB	dc.b 0
	dc.b SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD
	dc.b 0					;2
	dc.w plot_SCB				;3
	dc.w bll_data				;5
	dc.w 80-14				;7
bll_y	dc.w 90					;9
	dc.w $200				;11
	dc.w $200				;13

	;; Writing low-byte in SUZY space clears highbyte!
SUZY_addr
	db $09			; also color index for BLL sprite
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
	dc.b 0					;2
	dc.w 0					;3
pd2
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

	echo "Size:%dsize  Free:%dfree"
