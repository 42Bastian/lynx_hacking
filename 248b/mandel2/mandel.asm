;;; ----------------------------------------
;;; Lynx Mandelbrot using Suzy, 8bit fix point
;;;
;;; 24 bytes free
;;; ----------------------------------------

	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/suzy.mac>

R_MAX		EQU -550 	; -2.15
I_MAX		EQU -310	; -1.21
ABBRUCH		EQU $10
DELTAI		EQU 6
DELTAR		EQU 81/2/8

 BEGIN_ZP
	;; drawing
screen		ds 2
x		ds 1
y		ds 1
temp		ds 1

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
	stz	$fd94
	stz	screen
 ENDIF

Start::
	lda	#USE_AKKU|SIGNED_MATH
	sta	SPRSYS

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
	lda	#160
	sta	x
        MOVEI	R_MAX,R0
.lx
	jsr	ITER
;;;------------------------------
;;; plot
;;;------------------------------
	;; A = color
	lda	x
	lsr
	txa
	bcc	.11
	asl
	asl
	asl
	asl
	sta	temp
	bra	.12
.11
	and	#$f
	ora	temp
	sta	(screen)

	inc	screen
	bne	.12
	inc	screen+1
.12
        CLC
        LDA	R0
        ADC	#DELTAR
        STA	R0
	bcc	.13
	inc	R0+1
.13
	dec	x
	bne	.lx

        CLC
        LDA	I0
        ADC	#DELTAI
        STA	I0
	bcc	.14
	inc	I0+1
.14
	dec	y
	bne	.ly
endless::
	bra	endless

ITER	LDA #31
	STA COUNTER

	MOVE I0,I	; I = I0

	ldx R0			; R = R0
	lda R0+1
LOOP_ITER
	sta R+1
	STX R
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
	STA I+1			; I=2*R*I+I0

	SEC
	LDA R2
	SBC I2
	TAX
	LDA R2+1
	SBC I2+1
	TAY

	CLC
	TXA
	ADC R0
	tax
	TYA
	ADC R0+1		;; A:X=R2-I2+R0

	DEC COUNTER
	bne LOOP_ITER
END_ITER
	ldx COUNTER
	rts

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
	LDA	MATHE_A+1
	ldy	MATHE_A+2
	clc
	rts
ITER_e
size	set ITER_e-ITER
	ECHO "ITER: %Dsize"
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
