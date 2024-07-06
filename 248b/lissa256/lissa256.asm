***************
* lissa256 - rotating 256 dot lissajous
* For: Sommarhack`24
* Author: 42Bastian
* Size: 248b
****************

	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/if_while.mac>

PH_A	equ 3
PH_B	equ 9
PH_C	equ 4

	;; fixed addresses which are 0

a	equ $e0
b	equ $e1
c	equ $e2
ppa	equ $e3
ppah	equ $e5

 BEGIN_ZP
tmp		ds 2
tmp1		ds 2
ptr		ds 2
base		ds 1
plot_x		ds 1
 END_ZP

sinus	EQU $400
sinus_h	EQU $b00

pa	equ $500
pb	equ $600
pc	equ $700
pa_h	equ $800
pb_h	equ $900
pc_h	equ $a00

 IFND LNX
	run	$200-3
	jmp	bll_init
 ELSE
	run	$200
 ENDIF

Start::
	stz	MATHE_E
	ldy	#128
	sty	base
singen:
	tya
	_IFEQ
	  dec	tmp+1
	_ENDIF
	dey
	dey

	clc
	tya
	adc	tmp1
	sta	tmp1

	sta	sinus,x
	eor	#$ff
	sta	sinus+128,x

	lda	tmp1+1
	adc	tmp+1
	sta	tmp1+1

	sta	sinus_h,x
	eor	#$ff
	sta	sinus_h+128,x

	inx
	bpl	singen

	ldy	#0
.loop0
	lda	#>pa
	sta	ppa+1
	lda	#>pa_h
	sta	ppah+1

	ldx	#a
	lda	#PH_A
	jsr	sine

	ldx	#b
	lda	#PH_B
	jsr	sine

	ldx	#c
	lda	#PH_C
	jsr	sine

	iny
	bne	.loop0

main:
	lda	base
	sta	$fd95
	eor	#$20
	sta	ptr+1
	sta	base
;;;------------------------------
;;; wait VBL
.v0
//->	ldy	$fd0a
//->	bne	.v0
	ldy	#0
;;;------------------------------
	stz	ptr
	tya
	ldx	#30
.clr
	sta	(ptr),y
	iny
	bne	.clr
	inc	ptr+1
	dex
	bne	.clr

//->	ldx	#0
.loopdraw
	lda	pb,x
	ldy	pb_h,x
	jsr	div128
	eor	#$ff
	adc	pa,x
	pha
	tya
	eor	#$ff
	adc	pa_h,x
	pha
	lda	pa,x
	ldy	pa_h,x
	jsr	div128
	sta	plot_x

	adc	pb,x
	sta	pb,x
	tya
	adc	pb_h,x
	sta	pb_h,x

	pla
	sta	pa_h,x
	pla
	sta	pa,x

	lda	pc,x
	asl
	lda	pc_h,x
	rol
	adc	#51
	sta	MATHE_C		; A = C * E
	lda	#80
	sta	MATHE_E+1
	dc.b	$5c,0,0		; nop with 8 cycles
	clc
	lda	MATHE_A+2
	adc	base
	sta	ptr+1
	lda	MATHE_A+1
	sta	ptr

	lda	plot_x
	adc	#80
	lsr
	tay
	lda	#$e
	bcs	.odd
	lda	#$e0
.odd
	ora	(ptr),y
	sta	(ptr),y

	inx
	bne	.loopdraw
	jmp	main

sine::
	clc
	adc	0,x
	sta	0,x
	tax
	lda	sinus,x
	sta	(ppa),y
	inc	ppa+1
	lda	sinus_h,x
	sta	(ppah),y
	inc	ppah+1
	rts

div128::
	asl
	tya
	ldy	#0
	rol
	bpl	.1
	dey
.1
	clc
	rts

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

;;; ----------------------------------------------------------------------
 IFND LNX
bll_init:

	;; Setup needed if loaded via BLL/Handy
	lda	#8
	sta	$fff9
	sei

	stz	$fc08
	stz	DISPADRL
	lda	#$20
	sta	DISPADRH

	ldx	#15
	lda	#$ff
.init
	sta	GREEN0,x
	sta	BLUERED0,x
	sec
	sbc	#$11
	dex
	bpl	.init
	stz	$fdaf

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
	stz	0

	ldy	#2
	lda	#0
	tax
	jmp	$200
 ENDIF
	echo "Size:%dsize  Free:%dfree"
