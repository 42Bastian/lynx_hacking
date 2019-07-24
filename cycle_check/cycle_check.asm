****************
*
* chained_scbs.asm
*
* (c) 42Bastian Schick
*
* July 2019
*


DEBUG		set 1
Baudrate	set 62500

_1000HZ_TIMER	set 7

IRQ_SWITCHBUF_USR set 1

	include <includes\hardware.inc>
****************
	MACRO DoSWITCH
	dec SWITCHFlag
.\wait_vbl
	bit SWITCHFlag
	bmi .\wait_vbl
	ENDM

****************
* macros
	include <macros/help.mac>
	include <macros/if_while.mac>
	include <macros/font.mac>
	include <macros/mikey.mac>
	include <macros/suzy.mac>
	include <macros/irq.mac>
	include <macros/newkey.mac>
	include <macros/debug.mac>
****************
* variables
	include <vardefs/debug.var>
	include <vardefs/help.var>
	include <vardefs/font.var>
	include <vardefs/mikey.var>
	include <vardefs/suzy.var>
	include <vardefs/irq.var>
	include <vardefs/newkey.var>
	include <vardefs/serial.var>
	include <vardefs/1000Hz.var>
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
	INITKEY
	INITFONT LITTLEFNT,RED,WHITE
//->	jsr Init1000Hz
	FRAMERATE 75
	; 75Hz => 126us per line

	jsr InitComLynx
//->	SETIRQ 0,HBL
	SETIRQ 2,VBL
	SCRBASE screen0,screen1
	SET_MINMAX 0,0,160,102

	lda #$c0
	ora _SPRSYS
	sta SPRSYS
	sta _SPRSYS

	lda	#$ff
	sta	TIMER7+TIM_BAKUP
	lda	#TIM_64us|TIM_RELOAD|TIM_COUNT
	sta	TIMER7+TIM_CNTRL1
	cli

	jmp again
	ALIGN 1024
again::
	clc
	stz	$ff
	stz	TIMER7+TIM_CNT
	ldx	#16
.l
	MACRO j
	adc	$1000
.\x
	ENDM

	REPT 512
	j
	ENDR
	dex
	beq	.x1
	jmp	.l
.x1
	  lda	TIMER7+TIM_CNT
	  eor	#$ff
	  inc
	  stz $fda0
	  stz CurrX
	  jsr PrintDezA
	  DoSWITCH
	jmp again

	MACRO SKIP1
	dc.b $02
	ENDM

; iter  obcode  count   us   cycles
;              of 64us  per opcode
; -----------------------------------
; 16384 xb,x3     76   0.297   1
; 16384 NOP      152   0.594   2
; 16384 x2       152   0.594   2
; 16384 adc imm  152   0.594   2
;  8192 adc zp   130   1.02    3.4
;  8192 adc abs  169   1.32    4.4
;  8192 jmp      122   0.953   3.2
;  8192 bra      122   0.953   3.2
;  8192 bCC       76   0.598   2.1	  ; branch not taken
;  8192 bCC      122   0.953   3.2    ; branch taken
;  8192 $dc,$fc  169   1.32    4.4
;  4096 $5c      177   2.77    2.6
;  4096 inc abs  130   2.03    6.8
;  4096 inc zp   111   1.73    5.8


	; iter  size opcode
	; 16384   1   0b..fb    5,0ms => 0,3us  => 1cycle
	; 16384   1   03..f3    5,0ms => 0,3us  => 1cycle
	; 16384   1   NOP       9,5ms => 0,58us => 2cycles
	; 16384   2   $02       9,5ms => 0,6us  => 2cycles
	; 8192    3   5c,dc,fc 11,0ms => 1,2us  => 4cylces
	; 8192    2   f4       11,0ms => 1,3us  => 4cylces
	; 8192    2   44        9,5ms => 1,2us  => 4cycles

****************
HBL::
	stz	$fdb0
	END_IRQ
VBL::
	dec $fda0
	IRQ_SWITCHBUF
	END_IRQ
****************
_cls::	lda #<clsSCB
	ldy #>clsSCB
	jmp DrawSprite

clsSCB
	dc.b $0,$10,0
	dc.w 0,clsDATA
	dc.w 0,0
	dc.w $100*10,$100*102
clsCOLOR
	dc.b $00
clsDATA
	dc.b 2,%01111100
	dc.b 0

****************
* INCLUDES
	include <includes/draw_spr.inc>
	include <includes/irq.inc>
	include <includes/1000Hz.inc>
	include <includes/serial.inc>
	include <includes/font.inc>
	include <includes/font2.hlp>
	include <includes/newkey.inc>
	include <includes/debug.inc>
	include <includes/hexdez.inc>
	align 2

pal
	STANDARD_PAL
