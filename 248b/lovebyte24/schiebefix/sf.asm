***************
* SchiebeFix
* Release: Lovebyte 2024
* Nano Game compo
* Size: 247
****************

	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/if_while.mac>

;;; ROM sets this address
screen0	 equ $2000

 BEGIN_ZP
initFlag	ds 1
ptr		ds 2
pattern		ds 2
color		ds 1
button		ds 1
playfield	ds 16
 END_ZP


 IFD LNX
	run	$200
 ELSE
	run	$200-3
	jmp	init
 ENDIF
Start::
	stz	SPRSYS		; clear FLIP flag
	lda	#$44
	sta	$fdb0		; background purple

	;; init playfield
	ldx	#15
	stx	BLUEREDF	; red
.initpf
	  txa
	  sta	playfield,x
	  dex
	bpl	.initpf

	stx	BLUERED1
	stx	GREEN1
	stz	initFlag
	inx			; => 0
main::
;;; ----------------------------------------
	jsr	drawPF
	;; wait for button
	lda	JOYPAD
	beq	.wb
	bit	#JOY_OPT1|JOY_OPT2
	bne	Start
.wb1	cmp	JOYPAD
	beq	.wb1
	smb7	initFlag
.wb
	bbs7	initFlag,.game
	lda	$fd0a
	adc	$fd02
	eor	button
.game
	sta	button

;;; ----------------------------------------
	txa
	and	#3
	tay
	phx			; save old position

	bbr7	button,.noup
	cpx	#4
	bcc	.noright
	dex
	dex
	dex
	dex
	bra	.noright
.noup
	bbr6	button,.nodown
	cpx	#12
	bcs	.noright
	inx
	inx
	inx
	inx
	bra	.noright
.nodown
	bbr5	button,.noleft
	tya
	beq	.noright
	dex
	bra	.noright
.noleft
	bbr4	button,.noright
	cpy	#3
	beq	.noright
	inx
.noright
	ply			; old position
	lda	playfield,x
	sta	playfield,y
	stz	playfield,x
	bra	main
;;; ----------------------------------------
drawPF:
	phx
	stz	ptr
	lda	#>($2c00)
	sta	ptr+1

	ldx	#15
.l
	ldy	#$ff		; red
	txa
	cmp	playfield,x	; tile at the right place?
	_IFNE
	  ldy	#$11		; white
	_ENDIF
	sty	color
	ldy	playfield,x	; get actual tile
	phx
	jsr	drawTile
	plx
	txa
	and	#3		; next line?
	_IFEQ
	  lda	#<(400-20)	; skip line of tile + 1 pixel line
	  ldy	#>(400-20)
	  jsr	incPtr
	_ENDIF
	dex
	bpl	.l
	plx
	rts
;;; ----------------------------------------
;;; tiles are placed like this
;;;
;;;  FEDC
;;;  89AB
;;;  4567
;;;  3210

drawTile::
	lda	_lo_0,y
	sta	pattern
	lda	_hi_0,y
	sta	pattern+1

	ldx	#3
.y
	ldy	#3
.x
	rol	pattern
	rol	pattern+1
	lda	#0
	_IFCS
	  lda	color
	_ENDIF
	sta	(ptr),y
	dey
	bpl	.x
	iny			; => 0
	lda	#80		; next line
	jsr	incPtr
	dex
	bpl	.y
	lda	#<(-320+5)	; revert Y, increment X
	ldy	#>(-320+5)
incPtr:
	clc
	adc	ptr
	sta	ptr
	tya
	adc	ptr+1
	sta	ptr+1
	rts

	;; data reversed!

_0000	equ %0000
_0001   equ %1000
_0010   equ %0100
_0011   equ %1100
_0100   equ %0010
_0101   equ %1010
_0110   equ %0110
_0111   equ %1110
_1000	equ %0001
_1001	equ %1001
_1010	equ %0101
_1011	equ %1101
_1100	equ %0011
_1101	equ %1011
_1110	equ %0111
_1111	equ %1111

	MACRO char_hi
_hi_\0
	dc.b (\1<<4)|(\2)
	ENDM

	MACRO char_lo
_lo_\0
	dc.b (\3<<4)|(\4)
	ENDM

	char_lo	0,_0000,_0000,_0000,_0000
	char_lo 1,_1111,_1110,_1100,_1000
	char_lo	2,_1111,_0111,_0011,_0001
	char_lo 3,_0000,_0110,_0110,_0000
	char_lo	4,_1100,_1100,_1000,_1000
	char_lo 5,_1011,_1001,_1011,_1000
	char_lo 6,_1011,_1011,_1011,_1011
	char_lo 7,_0011,_0011,_0001,_0001
	char_lo 8,_1011,_0111,_0111,_1110
	char_lo 9,_1110,_1111,_1111,_1000
	char_lo A,_1111,_0111,_1111,_0001
	char_lo B,_1100,_1101,_0100,_0111
	char_lo C,_1100,_1110,_1011,_1011
	char_lo D,_0001,_0011,_0110,_1110
	char_lo E,_1000,_1100,_1110,_0111
	char_lo F,_0011,_0111,_1100,_1101

	char_hi	0,_0000,_0000,_0000,_0000
	char_hi 1,_1111,_1110,_1100,_1000
	char_hi	2,_1111,_0111,_0011,_0001
	char_hi 3,_0000,_0110,_0110,_0000
	char_hi	4,_1100,_1100,_1000,_1000
	char_hi 5,_1011,_1001,_1011,_1000
	char_hi 6,_1011,_1011,_1011,_1011
	char_hi 7,_0011,_0011,_0001,_0001
	char_hi 8,_1011,_0111,_0111,_1110
	char_hi 9,_1110,_1111,_1111,_1000
	char_hi A,_1111,_0111,_1111,_0001
	char_hi B,_1100,_1101,_0100,_0111
	char_hi C,_1100,_1110,_1011,_1011
	char_hi D,_0001,_0011,_0110,_1110
	char_hi E,_1000,_1100,_1110,_0111
	char_hi F,_0011,_0111,_1100,_1101
End:

size	set End-Start
free	set 249-size

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree"
;;; ----------------------------------------
 IFND LNX
init::
	;; Setup needed if loaded via BLL/Handy
	stz	$fff9
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

	ldy	#2
	lda	#0
	tax

	jmp	Start
 ENDIF
