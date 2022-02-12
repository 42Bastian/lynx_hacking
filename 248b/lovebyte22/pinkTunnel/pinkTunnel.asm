***************
* pinkTunnel - Reworked TUEF
* 190 bytes
****************
	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/if_while.mac>
	include <macros/suzy.mac>

 BEGIN_ZP
	;; drawing
screen		ds 2
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
table		ds 16
 END_ZP

screen0		equ $2000
angle		equ $4000
dist		equ $8000

 IFND LNX
	run	$200-3

	jmp	Init
 ELSE
	run	$200
 ENDIF

Start::
;;; grey scale palette
	ldx	#15
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
	sta	dptr+1		; $40
	sta	SPRSYS		; USE_AKKU
	asl
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
	sbc	(dptr),y
	and	#8
	beq	.cont
	lda	(lptr),y	; darken
	bra	.cont
;;; --------------------
.xx
	;; approximate angle as sin(alpha)

//->	stz	MATHE_AKKU+2	; clear AKKU+2 and AKKU+3
	lda	y
	jsr	square

	stx	y2+1
	ldx	#4
.mul16
	asl
	rol	y2+1
	dex
	bne	.mul16

	pha			; lo(32*y^2)

	lda	x
	jsr	square

	sta	MATHE_B
	stx	MATHE_B+1	; a:x = x^2+y^2

	asl
	txa
	rol
	sta	(lptr),y	; l = (x^2+y^2)/128

	pla			;y2
	ldx	y2+1
	jsr	div		; 32*y^2/(x^2+y^2) ~= 32*sin^2(alpha)

	tax
	lda	y
	eor	x
	asl
	txa
	bcc	.nodiv		;if ( (x<0)^(y<0) ) a ^= 15
	eor	#15
.nodiv
	sta	temp

	;; calculate depth
//->	lda	#0
	ldx	#$38
	jsr	div		;depth = $38??/(x^2+y^2)
	clc
	adc	temp
	sta	(dptr),y

.cont
	sta	(screen),y
	iny
	bne	.noinc
	inc	lptr+1
	inc	dptr+1
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
//->	inc
.1	sta	MATHE_C
	;; Y:A = MATHE_C * A:X
mul::
	sta	MATHE_E+1

	WAITSUZY
	lda	MATHE_AKKU+1
	ldx	MATHE_AKKU+2
	rts
div:
	sta	MATHE_A+2
	stx	MATHE_A+3
	WAITSUZY
	lda	MATHE_D+2
	rts
;;;------------------------------

End:
size	set End-Start
free	set 128-size

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF
 IFND LNX
Init::
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

	stz	$fd94
	lda	#$20
	sta	$fd95
	lda	#$fa
	sta	5
	stz	0

	MOVEI dummy_irq,$fffe

	ldy	#2
	lda	#0
	tax

	jmp	Start
dummy_irq:
	rti
 ENDIF

	echo "Size:%dsize  Free:%dfree"

	END
