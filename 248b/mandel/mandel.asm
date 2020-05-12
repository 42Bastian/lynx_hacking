	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/suzy.mac>

FIX_BITS	EQU 11
R_MAX		EQU -4400	; = -2.07
I_MAX		EQU -2662	; = -1.59
ABBRUCH		EQU $20;00	; =  4.0
DELTAI		EQU 52
DELTAR		EQU 81

 BEGIN_ZP
	;; drawing
screen		ds 2
x		ds 1
y		ds 1
temp		ds 2

	;; Mandelbrot
R0		DS 2
I0		DS 2
R		DS 2
I		DS 2
R2		ds 2
I2		ds 2
COUNTER		ds 1
DUMMY		ds 4

 END_ZP

screen0		equ $4000

 IFD LNX
	run	$200
 ELSE
	run	$400
	lda	#8
	sta	$fff9
	cli
 ENDIF

Start::
	lda	#USE_AKKU|SIGNED_MATH
	sta	SPRSYS

//->	stz	$fd94
//->	stz	screen
	sta	$fd95
	sta	screen+1

	lda	#$ff
	ldy	#32
.pal
	sta	$fda0-1,y
	sec
	sbc	#$11
	dey
	bne	.pal

        MOVEI	I_MAX,I0
	lda	#102
	sta	y

.ly
	lda	#80
	sta	x
        MOVEI	R_MAX,R0
.lx
	phy
	jsr	ITER
	ply
//->	and	#$f
	sta	temp
	asl
	asl
	asl
	asl
	ora	temp
	sta	(screen),y
	iny
	bne	.0
	inc	screen+1
.0
//->        CLC
        LDA	R0
        ADC	#DELTAR
        STA	R0
	bcc	.1
	inc	R0+1
.1
	dec	x
	bne	.lx

        CLC
        LDA	I0
        ADC	#DELTAI
        STA	I0
	bcc	.2
	inc	I0+1
.2
	dec	y
	bne	.ly
endless::
	bra	endless


ITER	LDA #32			;MAX_ITER
	STA COUNTER

	MOVE I0,I	; I = I0
	MOVE R0,R	; R = R0

LOOP_ITER
	LDX R
	LDA R+1
	jsr square

	STA R2
	STY R2+1

	LDX I
	LDA I+1
	jsr square

	STA I2
	ADC R2
	tya
	STA I2+1
	ADC R2+1

	CMP #ABBRUCH	; R^2+I^2 >=4
	BCS END_ITER

	LDA R
	rol
	tax
	LDA R+1
	rol
	jsr mul			; I is already in MATHE_C!

	ADC I0
	STA I
	tya
	ADC I0+1
	STA I+1		; I=2*R*I+I0

	SEC
	LDA R2
	SBC I2
	TAY
	LDA R2+1
	SBC I2+1
	TAX

	CLC
	TYA
	ADC R0
	STA R
	TXA
	ADC R0+1
	STA R+1		; R=R2-I2+R0

	DEC COUNTER
	bne LOOP_ITER
END_ITER
	lda COUNTER
	lsr
	RTS

	;; Y:A = A:X*A:X
square::
	stx	MATHE_C
	sta	MATHE_C+1
	;; Y:A = MATHE_C * A:X
mul::
	stx	MATHE_E
	sta	MATHE_E+1

	WAITSUZY
	;; normalize
	LDA	MATHE_A+3
	STA	DUMMY+3
	LDA	MATHE_A+2
	STA	DUMMY+2
	LDA	MATHE_A+1
	LDY	#FIX_BITS-8
LOOP1	LSR	DUMMY+3
	ROR	DUMMY+2
	ROR
	DEY
	BNE	LOOP1
	clc
	ldy	DUMMY+2
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
