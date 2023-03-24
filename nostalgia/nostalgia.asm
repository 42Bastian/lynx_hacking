;;; (2nd) STNICCC2000 port for the Lynx
;;; 2023 by 42Bastian
;;;

_1000HZ_TIMER	set 7	; timer#

;;->FRAMECOUNTER	set 1		; define to show current frame
IRQ_SWITCHBUF_USR set 1

BlockSize 	equ 2048
 IFD LNX
SCENE_1ST_BLOCK	equ 4
 ELSE
SCENE_1ST_BLOCK	equ 3
 ENDIF

	include <includes/hardware.inc>
* macros
	include <macros/help.mac>
	include <macros/if_while.mac>
	include <macros/mikey.mac>
	include <macros/suzy.mac>
	include <macros/font.mac>
	include <macros/irq.mac>

* variables
	include <vardefs/help.var>
	include <vardefs/mikey.var>
	include <vardefs/suzy.var>
	include <vardefs/font.var>
	include <vardefs/irq.var>
	include <vardefs/1000Hz.var>

	include "poly8.var"
*
* local MACROs
*
	MACRO CLS
	lda \0
	jsr cls
	ENDM

*
* vars only for this program
*

 BEGIN_ZP
CurrBlock	ds 1
BlockByte	ds 2
rerun		ds 1

points		ds 1
frame		ds 2
code		ds 1
color		ds 1
irq_vektoren	ds 16

frameInfo	ds 2
dir		ds 1
lastTime	ds 2

x1		ds 1
x2		ds 1
x3		ds 1
xn		ds 15

y1		ds 1
y2		ds 1
y3		ds 1
yn		ds 15

 END_ZP

screen0		equ $fff0-SCREEN.LEN
screen1		equ screen0-SCREEN.LEN

 IFD LNX
	run  $1ff		 ; code directly after variables
	dc.b 2+((end-Start)>>8)
 ELSE
	run $200
 ENDIF
Start::				; Start-Label needed for reStart
	jmp	init
main:
	INITFONT LITTLEFNT,0,15

	SETRGB pal		; set palette

	lda	#160
	sta	cls_size+1
	jsr	printHello
	SWITCHBUF
	jsr	printHello
	lda	#128
	sta	cls_size+1

.again
	lda	#SCENE_1ST_BLOCK
	sta	CurrBlock
	jsr	SelectBlock

	lda	_1000Hz		; sync on interrupt
.wait	cmp	_1000Hz
	beq	.wait

	stz	_1000Hz
	stz	_1000Hz+1

 IFD FRAMECOUNTER
	stz	frame
	stz	frame+1
 ENDIF

.next_frame
	_IFEQ	rerun
	  jsr	storePos
	_ELSE
	   jsr	seekPos
	_ENDIF

	CLS	#0
	jsr	play
	sta	code
	jsr	drawFrame
	_IFNE	rerun
	SET_XY	0,0		; set FONT-cursor
	LDAY	info1
	jsr	print
	lda	lastTime+1
	jsr	PrintHex
	lda	lastTime
	jsr	PrintHex
	LDAY	ms
	jsr	print
	_ENDIF
 IFD FRAMECOUNTER
	SET_XY	0,0		; set FONT-cursor
	lda	frame+1
	jsr	PrintHex
	lda	frame
	jsr	PrintHex
 ENDIF
	SWITCHBUF
	_IFEQ dir
	  inc	frame
	  _IFEQ
	    inc	frame+1
	  _ENDIF
	  lda	frame+1
	  cmp	#>423
	  bne	.next_frame
	  lda	frame
	  cmp	#<423
	  bne	.next_frame
	_ELSE
	  sec
	  lda frame
	  sbc #1
	  sta frame
	  _IFCC
	    dec frame+1
	  _ENDIF
	  ora	frame+1
	  bne	.next_frame
	_ENDIF

.endofscene
	lda	#1
	eor	dir
	sta	dir

	lda	_1000Hz
	sta	lastTime
	lda	_1000Hz+1
	sta	lastTime+1
	tsb	rerun
	jmp	.again

****************
cls::	sta cls_color
	LDAY clsSCB
	jmp _DrawSprite

clsSCB	dc.b $c0,$90,$00
	dc.w 0,cls_data
	dc.w 0,0		; X,Y
cls_size:
	dc.w 160*$100
	dc.w 102*$100		; size_x,size_y
cls_color
	dc.b $00

cls_data
	dc.b 2,$10,0

drawFrame::
	LDAY frameSCB
	jmp _DrawSprite
frameSCB::
	dc.b $c4,$90,$00
	dc.w .nxtscb1,cls_data
	dc.w -1,-1
	dc.w 130*$100,$100
	dc.b $0f
.nxtscb1:
	dc.b $c4,$90|SPRCTL1_PALETTE_NO_RELOAD,$00
	dc.w .nxtscb2,cls_data
	dc.w -1,100
	dc.w 130*$100,$100
.nxtscb2:
	dc.b $c4,$90|SPRCTL1_PALETTE_NO_RELOAD,$00
	dc.w .nxtscb3,cls_data
	dc.w -1,-1
	dc.w $100,102*$100
.nxtscb3:
	dc.b $c4,$90|SPRCTL1_PALETTE_NO_RELOAD,$00
	dc.w 0,cls_data
	dc.w 128,-1
	dc.w $100,102*$100


;;; ----------------------------------------
play::
	jsr	getbyte
	cmp	#$fe
	beq	.done
	cmp	#$ff
	beq	.done

	sta	color
	and	#$f
	sta	points
	tax
.getcoor
	jsr	getbyte
	lsr
	sta	x1-1,x
	jsr	getbyte
	lsr
	sta	y1-1,x
	dex
	bne	.getcoor

	jsr	poly
	bra	play
.done
	clc
	rts

poly:
	jsr	triangle8__

	lda	points
	sec
	sbc	#3
	_IFNE
	  sta	points
	  ldx	#4-1
.nxtp
	  phx
	  lda	x3
	  sta	x2
	  lda	y3
	  sta	y2
	  lda	x1,x
	  sta	x3
	  lda	y1,x
	  sta	y3
	  jsr	triangle8__
	  plx
	  inx
	  dec	points
	  bne	.nxtp
	_ENDIF
	rts

storePos::
	lda	CurrBlock
	dec
	sta	(frameInfo)
	lda	BlockByte+1
	ldy	#2
	sta	(frameInfo),y
	dey
	lda	BlockByte
	sta	(frameInfo),y
	clc
	lda	frameInfo
	adc	#3
	sta	frameInfo
	_IFCS
	  inc	frameInfo+1
	_ENDIF
	rts

seekPos::
	lda	(frameInfo)
	sta	CurrBlock
	jsr	SelectBlock
	ldy	#1
	lda	(frameInfo),y
	sta	BlockByte
	eor	#$ff
	tax
	iny
	lda	(frameInfo),y
	sta	BlockByte+1
	eor	#$7
	tay
.l	inx
	_IFEQ
	  iny
	  beq	.exit
	_ENDIF
	lda	$fcb2
	bra	.l

.exit
	_IFEQ	dir
	clc
	lda	#3
	adc	frameInfo
	sta	frameInfo
	_IFCS
	  inc	frameInfo+1
	_ENDIF
	_ELSE
	sec
	lda	frameInfo
	sbc	#3
	sta	frameInfo
	_IFCC
	  dec	frameInfo+1
	_ENDIF
	_ENDIF
	rts

getbyte::
	lda	$fcb2
	inc	BlockByte
	beq	.9
	rts
.9
	inc	BlockByte+1
	beq	SelectBlock
_rts
	rts
****************
* Select a block
****************
SelectBlock
	pha
	phx
	phy
	lda CurrBlock
	inc CurrBlock
	ldx #2
	ldy #3
	SEC
	BRA .SBL2
.SLB0
	STX $FD8B
	CLC
.SLB1
	STY $FD87
.SBL2
	STX $FD87
	ROL
	STZ $FD8B
	BEQ .exit
	BCS .SLB0
	BRA .SLB1
.exit
	lda _IOdat
	sta $fd8b
	stz BlockByte
	lda #$100-(>BlockSize)
	sta BlockByte+1

	ply
	plx
	pla
	RTS

VBL::
	phy
	_IFMI SWITCHFlag
	stz SWITCHFlag
	ldx ScreenBase
	ldy ScreenBase+1
	lda ScreenBase2
	sta ScreenBase
	sta VIDBAS
	lda ScreenBase2+1
	sta ScreenBase+1
	sta VIDBAS+1
	stx ScreenBase2
	sty ScreenBase2+1
	stx $fd94
	sty $fd95
	_ENDIF
	ply
	END_IRQ

printHello::
	stz	VOFF
	stz	HOFF
	CLS	#0		; clear screen with color #0
	SET_MINMAX 2,0,160,102	; screen-dim. for FONT.INC
	SET_XY	2,2		; set FONT-cursor
	LDAY	hello
	jsr	print

	SET_MINMAX 147,0,160,102	; screen-dim. for FONT.INC
	SET_XY	147,2		; set FONT-cursor
	LDAY	hello2
	jsr	print

	lda	#-16
	sta	HOFF
	lda	#$ff
	sta	HOFF+1
	sta	VOFF
	sta	VOFF+1

	rts

info1	db	"TIME (HEX): ",0
ms:
	db "ms",0
hello:
	db " L",13
	db " Y",13
	db " N",13
	db " X",13
	db "  ",13
	db " N",13
	db " O",13
	db " S",13
	db " T",13
	db " A",13
	db " L",13
	db " G",13
	db " I",13
	db " A",0

hello2:
	db " 4",13
	db " 2",13
	db " B",13
	db " a",13
	db " s",13
	db " t",13
	db " i",13
	db " a",13
	db " n",13
	db "  ",13
	db " 2",13
	db " 0",13
	db " 2",13
	db " 3",0

****************
* INCLUDES
_1000HzIRQ::
	inc _1000Hz
	beq .cont1
	END_IRQ
.cont1
	inc _1000Hz+1
	beq .cont2
	END_IRQ
.cont2
	inc _1000Hz+2
	END_IRQ

	include <includes/font.inc>
	include <includes/irq.inc>
	include <includes/font2.hlp>
	include <includes/hexdez.inc>
	include <includes/draw_spr.inc>
	include "poly8.inc"

pal:
	DP 000,111,241,124,343,344,464,447,448,594,7D3,64B,799,8BB,93F,FFF

;;; ----------------------------------------
;;; Init code, will be overwritten
init:
	START_UP		; set's system to a known state
	CLEAR_ZP		; clear zero-page

	INITMIKEY
	INITSUZY
	INITIRQ irq_vektoren	; set up interrupt-handler

	jsr Init1000Hz
        FRAMERATE 60

        SETIRQ 2,VBL
	SCRBASE screen0,screen1
	MOVE	ScreenBase,VIDBAS
	  MOVEI	framePositions,frameInfo
	cli
	jmp	main

Init1000Hz::
	php
	sei
	lda #249
	sta $fd00+_1000HZ_TIMER*4
	lda #%10011010	; 250KHz
	sta $fd01+_1000HZ_TIMER*4
	stz _1000Hz
	stz _1000Hz+1
	stz _1000Hz+2
	SETIRQVEC _1000HZ_TIMER,_1000HzIRQ
	plp
	rts

framePositions:
	ds	425*3
end:

free	equ screen1-end
	echo "fi: %HframePositions"
	echo "init: %hinit"
	echo "end: %hend"
	echo "screen0:%Hscreen0"
	echo "screen1:%Hscreen1"
	echo "free:%Hfree"
 IFD LNX
 IF (end - Start) > SCENE_1ST_BLOCK*2048
	echo "Fix start block!!"
 ENDIF
 ENDIF
