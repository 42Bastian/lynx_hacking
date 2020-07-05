;;; ----------------------------------------
;;; tuef - TUnnelEFect
;;; 2 bytes free
;;; (c) 42Bastian / June 2020
;;; ----------------------------------------

	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/suzy.mac>

 BEGIN_ZP
	;; drawing
screen		ds 2
aptr		ds 2
dptr		ds 2
dummy1		ds 1
lptr		ds 2

x		ds 1
y		ds 1
y2		ds 2
temp		ds 1
d		ds 2
ox		ds 1
oy		ds 1
 END_ZP

screen0		equ $2000
angle		equ $4000
dist		equ $8000
light		equ $c000

 IFD LNX
	run	$200
 ELSE
	run	$400
	;; Setup needed if loaded via BLL/Handy
	lda	#8
	sta	$fff9
	cli
	lda	#$20
	stz	$fd94
	stz	screen
	sta	$fd95

	stz 	$fd50
	stz	temp

	ldx	#0
	ldy	#8192/256
.cls
	stz	$2000,x
.cls1
	stz	$6000,x
	inx
	bne	.cls
	inc	.cls+2
	inc	.cls1+2
	dey
	bpl	.cls
	ldy	#2

	ldx	#31
	lda	#$ff
.init
	sta	$fda0,x
	dex
	bne	.init
	stz	0
	stz	1
	stz	2
	stz	3
	stz	4
	stz	7
	stz	8
	stz	9
 ENDIF

Start::
	;; Init palette yellow'ish
	ldx	#31
.pal
	txa
	sta	$fda0,x
	dex
	bpl	.pal

again:
	dec	ox
	stz	screen
	lda	#>screen0	; $20
	sta	screen+1
	asl
	sta	aptr+1		; $40
	asl
	sta	dptr+1		; $80

	lda	#USE_AKKU|SIGNED_MATH ;== $C0
	sta	SPRSYS
	sta	lptr+1
	ldy	#0

	lda	#-25
	sta	y
.ly1
	lda	#-40
	sta	x
.lx1
	bra	.xx		; self mod' after table calculation
;;; --------------------
//->	clc
	lda	ox		; going deeper and deeper and ...
	adc	(dptr),y
	sta	temp
	lda	ox		; rotate
	adc	(aptr),y
	eor	temp		; XOR pattern
	and	#8
	beq	.cont
	lda	(lptr),y	; darken
	bra	.cont
;;; --------------------
.xx
	;; approximate angle as sin(alpha)

	stz	MATHE_AKKU+2	; clear AKKU+2 and AKKU+3
	lda	y
	jsr	square

	stx	y2+1
	ldx	#5
.mul32
	asl
	rol	y2+1
	dex
	bne	.mul32
	sta	y2		; 32*y^2

	lda	x
	jsr	square
	phx
	sta	d		; a:x = x^2+y^2

	sta	MATHE_B
	stx	MATHE_B+1
	lda	y
	beq	.nodiv

	lda	y2
	ldx	y2+1
	jsr	div		; 32*y^2/(x^2+y^2) ~= 32*sin^2(alpha)

	tax
	lda	y
	eor	x
	asl
	txa
	bcc	.nodiv		;if ( (x<0)^(y<0) ) a ^= 31
	eor	#31
.nodiv
	sta	(aptr),y	; angle (not quiete)

	;; calculate depth
	lda	#0
	ldx	#$38
	jsr	div		;depth = $3800/(x^2+y^2)
	sta	(dptr),y

	;; calculate brightness
	pla			; d+1

	asl	d
	rol
	asl	d
	rol

	cmp	#15
	bcc	.nolimit2
	lda	#15
.nolimit2
	sta	temp
	tax
	beq	.no
	dec

	asl
	asl
	asl
	asl
.no
	ora	temp
	sta	(lptr),y	; l = d/64

.cont
	sta	(screen),y
	iny
	bne	.noinc
	inc	lptr+1
	inc	dptr+1
	inc	aptr+1
	inc	screen+1
.noinc
	inc	x
	lda	x
	cmp	#40
	lbne	.lx1
	asl
	adc	screen
	sta	screen
	bcc	.2
	inc	screen+1
.2
	inc	y
	lda	y
	cmp	#26
	lbne	.ly1
	stz	.lx1+1		;=> bra *+0
	jmp	again

	;; Y:A = A:X*A:X
square::
	bpl	.1
	eor	#$ff
	inc
.1	sta	MATHE_C
	;; Y:A = MATHE_C * A:X
mul::
	sta	MATHE_E+1

	WAITSUZY
	lda	MATHE_AKKU+1
	ldx	MATHE_AKKU+2
	rts
div:
	sta	MATHE_A+1
	stx	MATHE_A+2
	stz	MATHE_A+3
	WAITSUZY
	lda	MATHE_D+1
	rts

;;; ----------------------------------------
End:
size	set End-Start

free 	set 249-size

	echo "Size:%dsize  Free:%dfree"
	; fill remaining space
	IF free > 0
	REPT	free
	dc.b	$42		; unused space shall not be 0!
	ENDR
	ENDIF
