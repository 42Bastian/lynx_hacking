***************
* plasma2.asm
****************

	include <includes/hardware.inc>
* macros
	include <macros/help.mac>
	include <macros/if_while.mac>
	include <macros/mikey.mac>
	include <macros/suzy.mac>

*
* vars only for this program
*

 BEGIN_ZP
x	ds 1
y	ds 1
offset	ds 1
temp	ds 1
 END_ZP

screen0	 equ $2000
 IFD LNX
	run	$200
 ELSE
	run	$400
 ENDIF

 IFND LNX
	lda #8
	sta $fff9
	cli
	stz	x
 ENDIF
Start::
	ldx #9-1
.mloop
	  ldy	SUZY_addr,x
	  lda	SUZY_data,x
          sta	$fc00,y
          dex
        bpl .mloop

	stz	$fd94
	sta	$fd95

	SETRGB	pal

.lx
	ldy	#101
.ly
	lda	x
	cmp	#160
	beq	endless

	sta	plot_x
	jsr	get_sin
	sta	temp

	tya
	sta	plot_y
	lsr
	jsr	get_cos
	adc	temp

	lsr
	sta	temp

	clc
	tya
	adc	x
	lsr
	jsr	get_sin
	adc 	temp
	lsr

	sta	plot_color

	lda	#<plot_SCB
	sta	$fc10
	lda	#>plot_SCB
	sta	$fc11

	lda	#1
	STA	$FC91
	STZ	$FD90
	STZ	$FD91
//->	STZ	$FD90

	dey
	bpl	.ly
	inc	x
	bra	.lx

endless::
//->	lda	$fcb0
//->	bne	.2
	ldx	#30
.vbl
	lda	$fd0a
	bne	.vbl
	dex
	bpl	.vbl
.2

VBL
	dey
	bpl	endless

	ldy	$fdbf
	ldx	#30
.1
	lda	$fda0,x
	sta	$fda1,x
	dex
	bpl	.1
	lda	$fdb0
	sta	$fda0
	sty	$fdb0
	ldy	#2
	bra 	endless

get_cos::
	clc
	adc	#8
get_sin::
	and	#$1f
	lsr
	tax
	lda	sin,x
	bcs	.99
	lsr
	lsr
	lsr
	lsr
.99
	and	#$f
	clc
	rts

sin:	dc.b $89,$ab,$cd,$ee
	dc.b $fe,$ed,$cb,$a9
	dc.b $76,$54,$32,$11
	dc.b $11,$12,$34,$56
pal:
	DP 604,715,725,736,746,857,867,878,888,898,8A9,8B9,9CA,9DA,9EB,9FB

SUZY_addr  db $09,$08,$92,$04,$06,$28,$2a,$83,$90
SUZY_data  db $20,$00,$24,$00,$00,$7f,$7f,$f3,$01

size	set *-Start
free 	set 249-size-18

	IF free > 0
	REPT	free
	dc.b	$42
	ENDR
	ENDIF

	;; must be at end
plot_SCB:
	dc.b SPRCTL0_16_COL |SPRCTL0_BACKGROUND_NON_COLLIDABLE // 0
	dc.b SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD  // 1
	dc.b 0						// 2
	dc.w 0						// 3
	dc.w plot_data					// 5
plot_x	dc.w 0						// 7
plot_y	dc.w 0						// 9
	dc.w $100,$100					// 11
plot_color:
	dc.b $0f					// 15
plot_data:
	dc.b 2,$10					// 16
End:
 IFND LNX
	dc.b 0
 ENDIF
size	set End-Start

	echo "Size:%dsize  Free:%dfree"
