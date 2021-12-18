***************
* Lynx port of "MONA"
* 61 bytes over limit
****************

	include <includes/hardware.inc>
	include <macros/help.mac>

;;; ROM sets this address
screen0	 equ $2000

 BEGIN_ZP
plot_color	ds 1
plot_x		ds 1
plot_y		ds 1
seed		ds 4
path_length	ds 2
dir		ds 1
ptr		ds 2
tmp		ds 1
 END_ZP

	run	$200

 IFND LNX
	;; Setup needed if loaded via BLL/Handy as .o file
	lda	#8
	sta	$fff9
	sei
	ldx	#14
.init
	lda	#$ff
	sta	$fda0,x
	sta	$fdb0,x
	dex
	bne	.init
	stz	$fdaf
	stz	$fdbf
	stz	$fda0
	stz	$fdb0

	lda	#$00
	ldy	#8192/256
.clr
	sta	$2000,x
	inx
	bne	.clr
	inc	.clr+2
	dey
	bpl	.clr

	lda	#$fa
	sta	5
	stz	0
//->	stz	$fd94
//->	lda	#$20
//->	sta	$fd95
	ldy	#2
	lda	#0
	tax
 ENDIF

Start::
;;; --------------------

//->	ldy	#2		// y = 2 from ROM
.pal
	lda	colors_g,y
	sta	$fda1,y
	lda	colors_br,y
	sta	$fdb1,y
	dey
	bpl	.pal

	lda	#$7e
	sta	seed+3
	lda	#$c8
	sta	seed+2
	stz	MATHE_E
	ldx	#63
main::
;;;------------------------------

	lda	brush_lo,x
	sta	seed
	sta	plot_x
	lda	brush_hi,x
	sta	seed+1
	sta	plot_y
	stx	plot_color
	stx	path_length+1
;;;------------------------------
.loop0
	lda	#32
	sta	path_length
.loop
	asl	seed
	rol	seed+1
	rol	seed+2
	rol	seed+3
	bcc	.noxor
	ldy	#3
.l1
	lda	mask,y
	eor	seed,y
	sta	seed,y
	dey
	bpl	.l1
	sta	dir
.noxor:
	bbs7	dir,.minus
	bbs1	dir,.xpl
	inc	plot_y
	dc.b	$AD		; Opcode: LDA nn
.xpl
	inc	plot_x
	bra	.e
.minus
	bbs1	dir,.xmi
	dec	plot_y
	dc.b	$AD		; Opcode: LDA nn
.xmi
	dec	plot_x
.e
	rmb7	plot_x
	rmb7	plot_y

	lda	plot_y
	cmp	#96
	bcs	.skip

	sta	MATHE_C
	lda	#80
	sta	MATHE_E+1
.ws
	bit	SPRSYS
	bmi	.ws

	lda	plot_x
	lsr
	clc
	adc	MATHE_A+1
	sta	ptr
	lda	MATHE_A+2
	adc	#$20
	sta	ptr+1
	ldy	#$f0
	lda	plot_color
	and	#3
	bbs0	plot_x,.1
	asl
	asl
	asl
	asl
	ldy	#$f
.1
	sta	tmp
	tya
	and	(ptr)
	ora	tmp
	sta	(ptr)
.skip
	dec	path_length
	bne	.loop
	dec	path_length+1
	bpl	.loop0
	dex
.done
	bmi	.done
	jmp	main


mask:	dc.b $b7,$1d,$c1,$04

brush_lo
	dc.b $39,$B9,$44,$37
	dc.b $A7,$CE,$2E,$9D
	dc.b $7B,$8F,$3D,$14
	dc.b $63,$AF,$3C,$40
	dc.b $C7,$72,$E2,$77
	dc.b $16,$BB,$09,$13
	dc.b $2C,$F1,$14,$96
	dc.b $14,$42,$2B,$31
	dc.b $51,$7A,$7D,$FC
	dc.b $2C,$AD,$59,$F7
	dc.b $47,$A3,$F5,$19
	dc.b $D6,$11,$9C,$93
	dc.b $D2,$B1,$80,$B5
	dc.b $5A,$3E,$78,$BD
	dc.b $0B,$91,$9B,$3C
	dc.b $2B,$9B,$BE,$0A
brush_hi
	dc.b $21,$2B,$2C,$9E
	dc.b $25,$96,$31,$AF
	dc.b $C0,$23,$B2,$1E
	dc.b $AD,$3E,$8D,$52
	dc.b $80,$AC,$B8,$18
	dc.b $E9,$3E,$0A,$04
	dc.b $53,$B0,$29,$8A
	dc.b $B1,$B2,$54,$D4
	dc.b $30,$D5,$0D,$7D
	dc.b $A3,$29,$08,$8A
	dc.b $A3,$90,$97,$DF
	dc.b $26,$3D,$20,$20
	dc.b $9C,$D0,$02,$70
	dc.b $B0,$B8,$93,$0E
	dc.b $1B,$8A,$F5,$0E
	dc.b $07,$2F,$37,$03

colors_g:
	dc.b $06
colors_br:
	dc.b $0a
	dc.b $4e
	dc.b $8e

End:
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

	echo "Size:%dsize  Free:%dfree"
