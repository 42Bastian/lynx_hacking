****************
*
* cycle_check.asm
*
* (c) 42Bastian Schick
*
* Feb. 2020
*


DEBUG		set 1
Baudrate	set 62500

IRQ_SWITCHBUF_USR set 1

	include <includes\hardware.inc>
****************
* macros
	include <macros/help.mac>
	include <macros/if_while.mac>
	include <macros/mikey.mac>
	include <macros/suzy.mac>
	include <macros/irq.mac>
	include <macros/debug.mac>
****************
* variables
	include <vardefs/debug.var>
	include <vardefs/help.var>
	include <vardefs/mikey.var>
	include <vardefs/suzy.var>
	include <vardefs/irq.var>
	include <vardefs/serial.var>
****************************************************

 BEGIN_ZP
ptr		ds 2
ptr1		ds 2
ptr2		ds 2
tmp		ds 1
*********************
 END_ZP

 BEGIN_MEM
irq_vektoren	ds 16
		ALIGN 4
screen0		ds SCREEN.LEN
screen1		ds SCREEN.LEN
 END_MEM
	run LOMEM
ECHO "START :%HLOMEM ZP : %HNEXT_ZP"
Start::
	sei
	cld
	CLEAR_MEM
	CLEAR_ZP
	ldx #0
	txs
	INITMIKEY
	INITSUZY
	SETRGB pal
	INITIRQ irq_vektoren
	FRAMERATE 75

	jsr InitComLynx

	SETIRQ 2,VBL
//->	SETIRQ 0,HBL
	SCRBASE screen0

	lda #$c0
	ora _SPRSYS
	sta SPRSYS
	sta _SPRSYS

	ldx	#1
	cli
main:
	stz	$fda0
	stz	$fdb0
	cpx 	#0
	bne	main
	ldy	#10
w0:
	lda	$fd00
w1:	cmp 	$fd02
	bne	w1
w2:	cmp	$fd02
	beq	w2
	dec	$fdb0

	REPT 10
	dc.b $5c,0,0
	ENDR

	stz	$fdb0
	dey
	bne	w0
	bra	main
//->	ALIGN	256
HBL:
	inx
	inx
	jmp	(test,x)

dummy:
	dec $FDa0
empty:
	stz $fda0
	stz $fdb0
	jmp w0

	MACRO defTest ; rept opcode
	ALIGN	256
test_\0:
	dec $FDa0
	REPT \1
	\2
	ENDR
	stz $fda0
	stz $fdb0
	jmp w0
	ENDM

reptCnt	set 8

	defTest a,reptCnt,dc.b $1b
	defTest b,2*reptCnt,dc.b $1b
	defTest c,3*reptCnt,dc.b $1b
	defTest d,4*reptCnt,dc.b $1b
	defTest e,5*reptCnt,dc.b $1b
	defTest f,6*reptCnt,dc.b $1b
	defTest g,7*reptCnt,dc.b $1b
	defTest h,8*reptCnt,dc.b $1b
	defTest i,9*reptCnt,dc.b $1b

	defTest j,reptCnt,adc $ff
	defTest k,reptCnt,inc $ff
	defTest l,reptCnt,{dc.b $f4,0}
	defTest m,reptCnt,{dc.b $5c,0,0}
	defTest n,reptCnt,nop

	MACRO entry ; test
	rept 5
	dc.w test_\0
	endr
	dc.w empty
cnt set cnt+6
	ENDM

cnt set 1
test:
	dc.w empty
	rept 40
	dc.w empty
	endr
//->	entry a
//->	entry b
//->	entry c
//->	entry d
//->	entry e
//->	entry f
//->	entry g
//->	entry h
//->	entry i
//->	entry m
//->	entry k
//->	entry l
//->	entry m
//->	entry n

	rept 107-cnt
	dc.w main
	endr

****************
VBL::
	ldx #0
	END_IRQ

****************
* INCLUDES
//->	include <includes/irq.inc>
	include "my_irq.inc"
	include <includes/serial.inc>
	include <includes/debug.inc>
	align 2

pal
	STANDARD_PAL
