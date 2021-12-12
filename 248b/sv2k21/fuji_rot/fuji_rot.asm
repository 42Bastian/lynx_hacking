***************
* Rotating Fuji/Lynx
* 1/0 bytes free.
****************

	include <includes/hardware.inc>
	include <macros/help.mac>

_FUJI		EQU 1
//->_LYNX		EQU 1

;;; ROM sets this address
screen0	 equ $2000

 BEGIN_ZP
ptr	ds 2
frame	ds 1
temp	ds 1
 END_ZP

	run	$200

 IFND LNX
	;; Setup needed if loaded via BLL/Handy
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

	ldy	#8192/256
.clr
	stz	$2000,x
	inx
	bne	.clr
	inc	.clr+2
	dey
	bpl	.clr

	lda	#$fa
	sta	5
	stz	0

	ldy	#2
	lda	#0
	tax
 ENDIF

Start::
main::
.v0
	lda	$fd0a
	bne	.v0
;;;------------------------------

	ldx	#8192/256	; = $20
	stx	ptr+1
//->	stz	ptr		; not needed, first 255 bytes are empty
	tay
.clr
	sta	(ptr),y
	iny
	bne	.clr
	inc	ptr+1
	dex
	bne	.clr

_inc
	inc	frame

	bpl	.xx
	lda	_inc
	eor	#$20
	sta	_inc
.xx

	ldx	#NUM_DOTS-1
.loop
	lda	dots,x
	and	#$f
	sec
	sbc	#8		; coordinates range -8..7
	pha
	asl
	asl
	asl
	sta	temp		;x*8

	lda	frame
	jsr	get_cos		; y = cos(a)
	pla
	jsr	mulAY		; x*co
	sbc	temp
	pha			; x1 = x*co-8x

	lda	frame
	jsr	get_sin
	jsr	mulY		; x*si
	eor	#$ff		; (C is set, so adc is +1)
	adc	temp		; z = -xsi+8x
 IFND _LYNX
	adc	frame
	adc	#66
	sta	$fdbe
 ELSE
	adc	#66+34
 ENDIF
	sta	MATHE_B		; prepare projection

	pla			; x1
	jsr	project
	adc	#80
	lsr
	pha			; byte offset

	lda	dots,x
	and	#$f0
	lsr
//->	sec			; C == 0 because of lsr
	sbc	#54+1		; y = ((y|x) >> 4-8)*8+10

	jsr	project
	adc	#51

	ldy	#80
	jsr	mulAY
	sta	ptr
	lda	MATHE_A+2
	adc	#$20-1
	sta	ptr+1
	ply			; plot_x
	lda	#$e
	ora	(ptr),y
	sta	(ptr),y
;;;------------------------------
	dex
	bpl	.loop
	jmp	main
;;;------------------------------
mulAY::
;;;------------------------------
	sta	MATHE_C		; A = C * E
mulY
	sty	MATHE_E+1
.2	bit	SPRSYS
	bmi	.2
	lda	MATHE_A+1
	sec
	rts

get_cos::
//->	clc
	adc	#8
get_sin::
	and	#$1f
	lsr
	tay
	lda	sin,y
	bcs	.99
	lsr
	lsr
	lsr
	lsr
.99
	and	#$f
	tay
	rts

sin:	dc.b $89,$ab,$cd,$ee
	dc.b $fe,$ed,$cb,$a9
	dc.b $76,$54,$32,$11
	dc.b $11,$12,$34,$56

;;; --------------------
;;;
;;; if ( xy < 0 ){
;;;     ret = 40*(-xy)/z;
;;;     ret = -ret;
;;;   } else {
;;;     ret = 40*xy/z;
;;;   }

project::
	tay			; save sign
	bpl	.0
	eor	#$ff
//->	inc
.0
	sta	MATHE_C
	lda	#32
	sta	MATHE_E+1	; == MATHA
.2
	bit	SPRSYS
	bmi	.2

	stz	MATHE_A+3	; == MATHE
.3
	bit	SPRSYS
	bmi	.3

	lda	MATHE_D+1	; == MATHC
	cpy	#0
	bpl	.4
	eor	#$ff		; negate result
//->	inc
.4
	clc
	rts

	MACRO coor
.yy	set ((\1+8)<<4)&$f0|((\0+8)&$f)
	dc.b .yy
	if \# > 2
.yy	set ((\3+8)<<4)&$f0|((\2+8)&$f)
	dc.b .yy
	endif
	if \# > 4
.yy	set ((\5+8)<<4)&$f0|((\4+8)&$f)
	dc.b .yy
	endif
	if \# > 6
.yy	set ((\7+8)<<4)&$f0|((\6+8)&$f)
	dc.b .yy
	endif
	if \# > 8
.yy	set ((\9+8)<<4)&$f0|((\8+8)&$f)
	dc.b .yy
	endif
	if \# > 10
.yy	set ((\11+8)<<4)&$f0|((\10+8)&$f)
	dc.b .yy
	endif
	if \# > 12
.yy	set ((\13+8)<<4)&$f0|((\12+8)&$f)
	dc.b .yy
	endif
	if \# > 14
.yy	set ((\15+8)<<4)&$f0|((\14+8)&$f)
	dc.b .yy
	endif
	if \# > 16
.yy	set ((\17+8)<<4)&$f0|((\16+8)&$f)
	dc.b .yy
	endif

	ENDM
  IFD _FUJI
;; 8765432101234567
;;
;;      1 11 1
;;      1 11 1
;;      1 11 1
;;     1  11  1
;;   11   11   11
;; 111    11    111
;;
;; 8765432101234567

NUM_DOTS	EQU 30
dots::
 coor                                  -3,-6, -1,-6, 0,-6,  2,-6
 coor                                  -3,-4, -1,-4, 0,-4,  2,-4
 coor                                  -3,-2, -1,-2, 0,-2,  2,-2
 coor                            -4, 0,       -1, 0, 0, 0,       3, 0
 coor               -6, 2, -5, 2,             -1, 2, 0, 2,            4, 2,  5, 2
 coor -8, 4, -7, 4, -6, 4,                    -1, 4, 0, 4,                   5, 4,  6, 4,  7,4
 ENDIF

 IFD _LYNX
;;; 8       0   5
;;;
;;; 1  1 1 1  1 1 1
;;; 1  1 1 11 1 1 1
;;; 1  1 1 1 11  1
;;; 1   1  1  1 1 1
;;; 111 1  1  1 1 1

NUM_DOTS	EQU 36
dots:
	coor -8,-4		; L
	coor -8,-3
	coor -8,-2
	coor -8,-1
	coor -8, 0, -7, 0 , -6,0

	coor -5,-4, -3,-4	; Y
	coor -5,-3, -3,-3
	coor -5,-2, -3,-2
	coor -4,-1, -4, 0

	coor  -1,-4, 2, -4	; N
	coor  -1,-3, 0, -3, 2,-3
	coor  -1,-2, 1, -2, 2,-2
	coor  -1,-1, 2,-1
	coor  -1, 0, 2, 0

	coor 4,-4, 6,-4		; X
	coor 4,-3, 6,-3
	coor 5,-2
	coor 4,-1, 6,-1
	coor 4, 0, 6, 0
 ENDIF

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
