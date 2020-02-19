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
	SETIRQ 0,HBL
	SCRBASE screen0

	lda #$c0
	ora _SPRSYS
	sta SPRSYS
	sta _SPRSYS

	cli

main:
	nop
	bra	main

	ALIGN	256
HBL:
	inx
	inx
	jmp	(test,x)

dummy:
	dec $FDA0
	stz $fda0
	END_IRQ

	MACRO defTest ; rept opcode
	ALIGN	256
test_\0:
	dec $FDA0
	REPT \1
	\2
	ENDR
	stz $FDA0
	END_IRQ
	ENDM

	defTest a,32,dc.b $1b
	defTest b,64,dc.b $1b
	defTest c,96,dc.b $1b
	defTest d,128,dc.b $1b
	defTest e,32,nop
	defTest f,32,adc $ff
	defTest g,32,inc $ff
	defTest h,32,inc $8000

	MACRO entry ; test
	rept 8
	dc.w test_\0
	endr
cnt set cnt+8
	ENDM

cnt set 1
test:
	dc.w 0
	entry a
	entry b
	entry c
	entry d
	entry e
	entry f
	entry g
	entry h

	rept 107-cnt
	dc.w dummy
	endr

****************
VBL::
	ldx #0
	stz $fda0
	END_IRQ

****************
* INCLUDES
	include <includes/irq.inc>
	include <includes/serial.inc>
	include <includes/debug.inc>
	align 2

pal
	STANDARD_PAL
