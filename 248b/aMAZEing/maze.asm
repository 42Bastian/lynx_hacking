***************
* Maze249
* 1 byte free.
****************

	include <includes/hardware.inc>
	include <macros/suzy.mac>
	include <macros/help.mac>

 IFD LNX
USE_BKPT             equ 0
 ELSE
USE_BKPT             equ 0
 ENDIF
        MACRO HANDY_BRKPT
nbkpt	set nbkpt+1
 IF USE_BKPT = 1
        cpx     $5aa5
        dc.b $ec,0,0    ; CPX $0000
 ENDIF
        ENDM



screen0	 equ $2000	; ROM sets this address
xstack	 equ $8000	; must be "negative" !
ystack	 equ $5800

 BEGIN_ZP
x		ds 1
y		ds 1
sp		ds 1
try		ds 1
xadd		ds 1
yadd		ds 1
ptr		ds 2
xstackbase	ds 2
ystackbase	ds 2
 END_ZP

nbkpt	set 0

	run	$200

 IFND LNX
	;; Setup needed if loaded via BLL/Handy
	lda	#8
	sta	$fff9
	sei
	lda	#0
	sta	$fd94
	lda	#$20
	sta	$fd95
	stz	$fd50
	ldy	#2
	stz	0
	lda	#$e
	sta	$fdae
	ldx	#15
.init
	txa
	sta	$fda0,x
	stz	$fdb0,x
	dex
	bne	.init

	ldy	#8192/256
.clr
	stz	$2000,x
	inx
	bne	.clr
	inc	.clr+2
	dey
	bne	.clr
	ldx	#5
.clr1	stz	0,x
	dex
	bpl	.clr1
	inx
	ldy	#2
	lda	#$fa
	sta	4+1
	stz	$fd20
	lda	#0
 ENDIF
;;; ----------------------------------------
Start::
	lda	#$ff
	sta	$fdaf
	sta	$fdbf
	stz	$fda0
	stz	$fdb0

	stz	xstackbase
	lda	#>xstack
	sta	xstackbase+1

	stz	ystackbase
	lda	#>ystack
	sta	ystackbase+1

	HANDY_BRKPT

again::
	stz	try
.retry
	lda	$fd02
	eor	$fd0a

	ldx	#0
	ldy	#0

	and	#3
	beq	.xplus
	dec
	beq	.xminus
	dec
	beq	.yplus
.yminus:
	dey
	dey
	lda	#8-2
.yplus:
	iny
	inc			; A = 2-1
	bra	.cont1
.xminus:
	dex
	dex
	lda	#4-1
.xplus:
	inx
.cont1
	inc		; A = 1
.cont
	tsb	try
	bne	.outofbounds

	txa
	stx	xadd
	asl
	clc
	adc	x
	cmp	#160
	bcs	.outofbounds
	tax
	cmp	#$fe
	beq	.outofbounds

	tya
	sty	yadd
	asl
	clc
	adc	y
	bmi	.outofbounds
	cmp	#102
	bcc	.ok

.outofbounds:
	lda	try
	cmp	#15
	bne	.retry
.pop
	ldy	sp
	bne	.pop1
	dec	ystackbase+1
	dec	xstackbase+1
.done
	bpl	.done
.pop1
	dey
	sty	sp
	lda	(xstackbase),y
	sta	x
	lda	(ystackbase),y
	sta	y
.toagain
	bra	again

//->.done
//->	HANDY_BRKPT
//->	bra	.done

.ok
	;; check for wall
	jsr	calcPtr
	beq	.push
	bcs	.loPixel
	asl
	bcs	.outofbounds
	dc.b	$a9	; opcode "lda #n" , skip lsr
.loPixel
	lsr
	bcs	.outofbounds

.push:
	ldy	sp
	lda	x
	sta	(xstackbase),y
	lda	y
	sta	(ystackbase),y
	inc	sp
	bne	.draw

	inc	xstackbase+1
	inc	ystackbase+1
.draw
	jsr	drawLine
	bra	.toagain

;;; --------------------
;;; X - x
;;; A - y
;;; => ptr and A = byte
calcPtr::
	sta	MATHE_E
	lda	#80
	sta	MATHE_C
	stz	MATHE_E+1
	WAITSUZY
	clc
	lda	MATHE_A
	sta	ptr
	lda	MATHE_A+1
	adc	#$20
	sta	ptr+1
	txa
	lsr
	tay
	lda	(ptr),y
	rts
;;; --------------------
;;; X - x
;;; A - y
drawLine::
	jsr	.draw
.draw
	clc
	lda	x
	adc	xadd
	sta	x
	tax
	clc
	lda	y
	adc	yadd
	sta	y

.drawPixel
	jsr	calcPtr
	bcs	.odd
	ora	#$f0
	dc.b	$ae	; opcode "ldx nn" => skip next instruction
.odd
	ora	#$0f
.exit
	sta	(ptr),y
	rts
;;;------------------------------

End:
 IFND LNX
	;; Lynx rom clears to zero after boot loader!
	dc.b 0
 ENDIF

size	set End-Start
IF USE_BKPT = 1
free	set 249-size+(nbkpt*6)
ELSE
free	set 249-size
ENDIF
	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree"
