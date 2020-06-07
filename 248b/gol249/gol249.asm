***************
* Game of Live
* 11/14 Bytes free!
****************

//->CLEAR_PAST	EQU 0		; if not defined, dead cells become zombies :-)

	include <includes/hardware.inc>
* macros
	include <macros/help.mac>

*
* vars only for this program
*

 BEGIN_ZP
screen		ds 2
pf1		ds 2
pf2		ds 2
x		ds 1
y		ds 1
temp		ds 2
ptr		ds 2
N		ds 1
 END_ZP

playfield1	equ $900
playfield2	equ $a00

;;; ROM sets this address
screen0		equ $2000

 IFD LNX
	;; BLL loader is at $200, so move up
	run	$200
 ELSE
	run	$400
 ENDIF

 IFND LNX
	;; Setup needed if loaded via BLL/Handy
	lda	#8
	sta	$fff9
	cli
	stz	screen
	stz	$fd94
	lda	#$20
	sta	$fd95
	ldx	#31
.init
	stz	$fda0,x
	dex
	bpl	.init
	ldx	#0
.init2
	stz	playfield1,x
	dex
	bne	.init2
	lda	#0
	stz	ptr
 ENDIF
Start::
 IF 0
	inc
	sta	playfield1+8*16+8
	sta	playfield1+9*16+8+1
	sta	playfield1+9*16+8
	sta	playfield1+9*16+8-1
	sta	playfield1+10*16+8
 ELSE
.1
	lda	$fe12,x
	lsr
	and	#1
	sta	playfield1,x
	dex
	bne	.1
 ENDIF
	ldx	#10
	stx	pf2+1
	dex
	stx	pf1+1
.mloop
	  ldy	SUZY_addr,x
	  lda	SUZY_data,x
          sta	$fc00,y
	  lda 	pal,x
	  sta	$fda0,x
	  stz	$fdb0,x
          dex
        bpl .mloop
.outer:
	lda	#15
	sta	y
.ly
	lda	#15
	sta	x
.lx
	dec	ptr
	stz	N
	ldx	x
	;; X for sprite
	txa
	asl
	adc	x
	asl
	sta	plot_x

	ldy	y
	;; Y for sprite
	tya
	asl
	adc	y
	asl
	sta	plot_y

	jsr	cell_dex	;x-1,y
	iny
	jsr	cell		;x-1,y+1
	jsr	cell_inx	;x  ,y+1
	jsr	cell_inx	;x+1,y+1
	dey
	jsr	cell		;x+1,y
	dey
	jsr	cell		;x+1,y-1
	jsr	cell_dex	;x  ,y-1
	jsr	cell_dex	;x-1,y-1

	ldx	#1
	ldy	ptr
	lda	N
	sta	plot_color

	ora	(pf1),y
	cmp	#3
	beq	.done
	dex
 IFD CLEAR_PAST
	stz	plot_color
 ENDIF
.done
	txa
	sta	(pf2),y
;;; ----------------------------------------
	lda	#<plot_SCB
	sta	$fc10
	lda	#>plot_SCB
	sta	$fc11

	lda	#1
	STA	$FC91
	STZ	$FD90
	STZ	$FD91
;;; ----------------------------------------
	dec	x
	bpl	.lx
	dec	y
	bpl	.ly

	lda	pf1+1
	ldx	pf2+1
	sta	pf2+1
	stx	pf1+1

	lsr			; A == 10 || A == 9 => DELAY = 5/4
;;;------------------------------
waitVBL
;;;------------------------------
.v1
	ldx	$fd0a
	bne	.v1
.v2
	ldx	$fd0a
	beq	.v2

	dec
	bpl	waitVBL
	jmp	.outer
;;;----------------------------------------
;;; check one cell
;;;----------------------------------------
cell_dex:
	dex
	dex
cell_inx:
	inx
cell::
	phy
	txa
	and	#$f
	sta	temp
	tya
	asl
	asl
	asl
	asl
	ora	temp
	tay
	lda	(pf1),y
	beq	.9
	inc	N
.9
	ply
	rts

pal:	db 0
****************
SUZY_addr  db $92,$83,$04,$06,$28,$09,$2a,$ff,$08,$90
SUZY_data  db $24,$f3,$00,$00,$7f,$21,$7f,$00,$00 ;
	;; must be at end
plot_SCB:
	dc.b SPRCTL0_16_COL |SPRCTL0_BACKGROUND_NON_COLLIDABLE // 0
	dc.b SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD  // 1
	dc.b 0						// 2
	dc.w 0						// 3
	dc.w plot_data					// 5
plot_x	dc.w 0						// 7
plot_y	dc.w 0						// 9
	dc.w $580,$580					// 11
plot_color:
	dc.b $0f					// 15
plot_data:
	dc.b 2,$10					// 16

End:
 IFND LNX
	dc.b 0
 ENDIF
size	set End-Start

free 	set 249-size

	echo "Size:%dsize  Free:%dfree"
	; fill remaining space
	IF free > 0
	REPT	free
	dc.b	0		; unused space shall not be 0!
	ENDR
	ENDIF
