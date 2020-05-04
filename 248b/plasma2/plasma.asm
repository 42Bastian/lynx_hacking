***************
* plasma2.asm
****************

	include <includes/hardware.inc>
* macros
	include <macros/help.mac>
	include <macros/if_while.mac>
	include <macros/mikey.mac>

*
* vars only for this program
*
 BEGIN_ZP
offset		DS 1
x		ds 1
y		ds 1
temp		ds 2
 END_ZP

screen0	 equ $2400

 IFD LNX
	run	$200
 ELSE
	run	$400
 ENDIF

Start::
	cli				// for BLL loader to allow re-loading
	lda	#$8
	sta	$fff9
	lda	#$f3
	sta	$fc83
	STA	$FC90			// b0 = BUS ENABLE (b1..b7 don't care)
	lda	#$24
	sta	$fc92

//->	stz	$fd94
//->	stz	$fc08
//->	lda	#>screen0
	sta	$fd95
	sta	$fc09

	SETRGB	pal

	lda	#160
	sta	x
.lx
	ldy	#101
.ly
	lda	x
	dec
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
	STZ	$FD90

	dey
	bpl	.ly
	dec	x
	bne	.lx

endless::
	lda	$fcb0
	bne	.2
	ldx	#30
.vbl
	lda	$fd0a
	cmp	#1
	bne	.vbl
	dex
	bpl	.vbl
.2

VBL
	dec 	offset
	bpl	.99
	lda 	#2
	sta	offset

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
.99
	bra endless

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

plot_SCB:
	dc.b SPRCTL0_16_COL |SPRCTL0_BACKGROUND_SHADOW  // 0
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
	dc.b 2,$10,0					// 16

pal:
	DP 604,715,725,736,746,857,867,878,888,898,8A9,8B9,9CA,9DA,9EB,9FB

End:
size	set End-Start


free 	set 248-size

	echo "Size:%dsize  Free:%dfree"
	; fill remaining space
	IF free > 0
	REPT	free
	dc.b	$42		; unused space shall not be 0!
	ENDR
	ENDIF

	dc.b 	$00	; end mark!
