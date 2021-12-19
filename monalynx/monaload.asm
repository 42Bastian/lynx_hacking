***************
* Lynx port of "MONA"
* Loader for LNX
****************

	include <includes/hardware.inc>
	include <macros/help.mac>

;;; ROM sets this address
screen0	 equ $2000

 BEGIN_ZP
path_length	ds 1
plot_color	ds 1
plot_x		ds 1
plot_y		ds 1
seed		ds 4
dir		ds 1
ptr		ds 2
tmp		ds 1
 END_ZP

mona	equ $231

	RUN	$200
Start::
//->	ldy	#2		// y = 2 from ROM
.pal
	lda	colors_g,y
	sta	$fda1,y
	lda	colors_br,y
	sta	$fdb1,y
	dey
	bpl	.pal
	iny
	inx
.load
	lda	RCART0
.store
	sta	mona,y
	iny
	bne	.load
	inc	.store+2
	dex
	bpl	.load

	;; Code moved from monalynx.asm to fill up to 49
	stz	MATHE_E
	lda	#$7e
	sta	seed+3
	bra	mona
colors_g:
	dc.b $06
colors_br:
	dc.b $0a
	dc.b $4e
	dc.b $8e

mask:	dc.b $b7,$1d,$c1,$04

End::
size	set End-Start
free	set 49-size

echo "Free %Dfree"

	IF free != 0
	echo "Size must be == 49!"
	ENDIF
	dc.b	$00		; end mark!
