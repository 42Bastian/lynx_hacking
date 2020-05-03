***************
* 256.ASM
****************

	include <includes/hardware.inc>
* macros
	include <macros/help.mac>
	include <macros/if_while.mac>
	include <macros/mikey.mac>
	include <macros/suzy.mac>

	include <macros/irq.mac>
	include <macros/debug.mac>
* variables
	include <vardefs/debug.var>
	include <vardefs/help.var>
	include <vardefs/mikey.var>
	include <vardefs/suzy.var>

*
* vars only for this program
*

 BEGIN_ZP
offset		DS 1
screen		ds 2
x		ds 1
y		ds 1
 END_ZP

screen0	 equ $4000

 IFD LNX
	run	$200
 ELSE
	run	$400
 ENDIF

Start::
	lda	#$c
	sta	$fff9
	lda	#<screen0
	sta	$fd94
	sta	$fc08
	sta	screen
	lda	#>screen0
	sta	$fd95
	sta	$fc09
	sta	screen+1

	SETRGB	pal

	lda	#102
	sta	y
	ldy	#0
.ly
	lda	#80
	sta	x
.lx
	lda	x
	jsr	get_sin
	sta	temp

	lda	y
	lsr
	jsr	get_cos
	clc
	adc	temp

	lsr
	sta	temp

	clc
	lda	x
	adc	y
	lsr
	jsr	get_sin
	clc
	adc 	temp
	lsr

	sta	temp
	asl
	asl
	asl
	asl
	ora	temp
	sta	(screen),y
	iny
	bne	.1
	inc	screen+1
.1
	dec	x
	bne	.lx
	dec	y
	bne	.ly

	cli
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
	jsr	VBL
	bra endless

get_cos::
	clc
	adc	#8
get_sin::
	and	#$1f
	tax
	lda	sin,x
	rts

sin:
	dc.b $8,$9,$a,$b,$c,$d,$e,$e
	dc.b $f,$e,$e,$d,$c,$b,$a,$9
	dc.b $7,$6,$5,$4,$3,$2,$1,$1
	dc.b $1,$1,$1,$2,$3,$4,$5,$6
****************

VBL::
	dec 	offset
	bpl	.99
	lda 	#2
	sta	offset

	lda	$fdaf
	ldx	$fdbf
	sta	temp
	ldy	#14
.loop
	lda	$fda0,y
	sta	$fda1,y
	lda	$fdb0,y
	sta	$fdb1,y
	dey
	bpl 	.loop
	lda	temp
	sta	$fda0
	stx	$fdb0
.99
	rts

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
