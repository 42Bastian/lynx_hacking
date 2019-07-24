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
	FRAMERATE 75

	jsr InitComLynx

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
	sec
	stz	$ff
	stz	TIMER7+TIM_CNT
	ldx	#32
.l
	MACRO j
	nop
//->	adc	$1000
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

;                    75Hz          |        60Hz           |        50Hz
; iter opcode  count   us   cycles | count    us   cycles  | count    us   cycles |
;              of 64us  per opcode | of 64us  per opcode   | of 64us  per opcode  |
; ---------------------------------------------------------------------------------
; 32K  xb,x3    152   0.297   1    |  148    0.289    1	   |  145    0.283    1
; 16K  NOP      152   0.594   2    |  147    0.578    2	   |  144    0.563    2
; 16K  x2       152   0.594   2	   |			   |
; 16K  adc imm  152   0.594   2    |			   |
;  8K  adc zp   130   1.02    3.4  |			   |
;  8K  adc abs  169   1.32    4.4  |  163    1.27     4.4  |
;  8K  jmp      122   0.953   3.2  |			   |
;  8K  bra      122   0.953   3.2  |			   |
;  8K  bCC n/t   76   0.598   2.1  |			   |
;  8K  bCC  /t  122   0.953   3.2  |			   |
;  8K  $dc,$fc  169   1.32    4.4  |			   |
;  4K  $5c      177   2.77    2.6  |			   |
;  4K  inc abs  130   2.03    6.8  |			   |
;  4K  inc zp   111   1.73    5.8  |			   |

; n/t not taken
;  /t taken


****************
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
