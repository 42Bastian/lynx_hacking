***************
* Lynx port of "MONA"
* Loader for LNX
****************

	include <includes/hardware.inc>
	include <macros/help.mac>

	include "monalynx.equ"

;;; ROM sets this address
screen0	 equ $2000

	include "monalynx.var"

	RUN	$200
StartLoad::
//->	ldy	#2		// y = 2 from ROM
.pal
	lda	colors_g,y
	sta	$fda1,y
	lda	colors_br,y
	sta	$fdb1,y
	dey
	bpl	.pal
.load
	iny
	lda	RCART0
	sta	(5),y		; ptr used by ROM
	cpy	#brush-Start-1
	bne	.load

	;; Code moved from monalynx.asm to fill up to 49
//->	lda	#$7e	// loaded from card
	sta	seed+3
	lda	#$c8
	sta	seed+2
	stz	MATHE_E
	ldy	#63
main:
	sty	plot_color
	lda	RCART0
	sta	seed
	sta	plot_x
	;; constants do no harm if executed, so no jump over
colors_g::
	dc.b $06		; => ASL $A
colors_br::
	dc.b $0a
	dc.b $4e		; => LSR $008e
	dc.b $8e
End::
size	set End-StartLoad
free	set 49-size

echo "Free in loader: %Dfree"

	IF free != 0
	echo "Size must be == 49!"
	ENDIF
	dc.b	$00		; end mark!
