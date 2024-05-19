;;; (2nd) STNICCC2000 port for the Lynx
;;; 2023 by 42Bastian
;;;

_1000HZ_TIMER	set 7	; timer#
SND_TIMER	set 1
_ABC_120HZ	set 1

//->FRAMECOUNTER	set 1		; define to show current frame
IRQ_SWITCHBUF_USR set 1

BlockSize 	equ 2048
 IFD LNX
SCENE_1ST_BLOCK	equ 4
 ELSE
SCENE_1ST_BLOCK	equ 3
 ENDIF

 IFND USE_TSC
LZ4	equ 1
TSC	equ 0
 ELSE
LZ4	equ 0
TSC	equ 1
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

 IF LZ4 = 1
	include "unlz4.var"
 ELSE
	include "untsc.var"
 ENDIF
	include "poly8.var"
	include "abcmusic.var"
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
dst		ds 2
rerun		ds 1

dpk_flip	ds 1
token_count	ds 1
depacking	ds 1
scenes		ds 1
points		ds 1
frame		ds 2
frameptr	ds 2
code		ds 1
color		ds 1
irq_vektoren	ds 16

ptr_x		ds 2
ptr_y		ds 2

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
scene2		equ screen1-20600
scene		equ scene2-20600

 IFD LNX
	run  $1ff		 ; code directly after variables
	dc.b 2+((end-Start)>>8)
 ELSE
	run $200
 ENDIF
Start::				; Start-Label needed for reStart
	jmp	init
main:
	INITFONT LITTLEFNT,0,8
.again
	SETRGB pal		; set palette

	lda	#160
	sta	cls_size+1

	jsr	printHello
	lda	rerun
	beq	.skip_time

	SET_XY	0,0		; set FONT-cursor
	LDAY	info1
	jsr	print
	pla
	jsr	PrintHex
	pla
	jsr	PrintHex
	pla
	jsr	PrintHex
	LDAY	ms
	jsr	print
.skip_time
	SWITCHBUF
	jsr	printHello

	lda	#SCENE_1ST_BLOCK
	sta	CurrBlock
	jsr	SelectBlock

	MOVEI	scene,dst
	stz	token_count
 IF LZ4 = 1
	jsr	unlz4
 ELSE
	jsr	untsc
 ENDIF
	dey
	bne	.w0
.dounlz4
 IF LZ4 = 1
	jsr	unlz4_cont
 ELSE
	jsr	untsc_cont
 ENDIF
	dey
	beq	.dounlz4
.w0
	lda	$fcb0
	beq	.w0

	jsr startSong

	lda	#128
	sta	cls_size+1

	lda	_1000Hz		; sync on interrupt
.wait	cmp	_1000Hz
	beq	.wait

	stz	_1000Hz
	stz	_1000Hz+1
	stz	_1000Hz+2

	stz	dpk_flip
 IFD FRAMECOUNTER
	stz	frame
	stz	frame+1
 ENDIF
	lda	#1
	sta	depacking

.next_frame
	lda	dpk_flip
	eor	#1
	sta	dpk_flip
	_IFEQ
	  MOVEI	scene,dst
	  MOVEI	scene2,frameptr
	_ELSE
	  MOVEI	scene2,dst
	  MOVEI	scene,frameptr
	_ENDIF

	lda	depacking
	beq	.noflip
 IF LZ4
	lda	#10
	sta	token_count
	jsr	unlz4		; initial depack of next chunk
 ELSE
	lda	#20
	sta	token_count
	jsr	untsc		; initial depack of next chunk
 ENDIF
	sty	depacking
	bra	.noflip
.loop
 IFD FRAMECOUNTER
	inc	frame
	_IFEQ
	  inc	frame+1
	_ENDIF
 ENDIF
	SWITCHBUF

.noflip
	jsr	play
	sta	code
	jsr	drawFrame
 IFD FRAMECOUNTER
	SET_XY	0,0		; set FONT-cursor
	lda	frame+1
	jsr	PrintHex
	lda	frame
	jsr	PrintHex
 ENDIF

	lda	depacking
	_IFNE
 IF LZ4 = 1
	  lda	#49
	  sta	token_count
	  jsr	unlz4_cont
 ELSE
	  lda	#70
	  sta	token_count
	  jsr	untsc_cont
 ENDIF
	  sty	depacking
	_ENDIF

	lda	code
	beq	.loop

.next:
	ldy	depacking
	_IFNE
.dpk1
 IF LZ4 = 1
	  jsr	unlz4_cont
 ELSE
	  jsr	untsc_cont
 ENDIF
	  dey
	  beq	.dpk1
	_ENDIF

	lda	code
	ldy	#0		; depack flag => no depacking
	inc
	beq	.endofscene
	cmp	#$fc+1		; pre-last frame?
	_IFNE
	  iny
	_ENDIF

	sty	depacking
	jmp	.next_frame

.endofscene
	lda	_1000Hz
	pha
	lda	_1000Hz+1
	pha
	lda	_1000Hz+2
	pha
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

titleSCB:
	dc.b $c4,$10,$00
	dc.w title2SCB,title
	dc.w 19-16,34-1,$100,$100
	dc.b $01,$23,$45,$67,$59,$AB,$CD,$E2

title2SCB:
	dc.b $c4|$20,$18,$00
	dc.w title3SCB,title
	dc.w 77-16,80-1,$80,$80

title3SCB:
	dc.b $c4,$18,$00
	dc.w frameSCB,title
	dc.w 66,6,$80,$80

;;; ----------------------------------------
.ende
	sec
	rts
play
	lda	(frameptr)
	sta	code
	bmi	.ende
	bit	#1
	beq	.nocls
	LDAY	clsSCB
	jsr	_DrawSprite
.nocls
	ldy	#1
	bbr1	code,.no_palette
	lda	(frameptr),y
	sta	temp
.sp	iny
	lda	(frameptr),y
	iny
	tax			;offset
	lda	(frameptr),y	; r
	iny
	sta	$fda0,x
	lda	(frameptr),y	; bg
	sta	$fdb0,x
	dec	temp
	bne	.sp

	clc
	tya
	ldy	#1
	adc	frameptr
	sta	frameptr
	_IFCS
	  inc	frameptr+1
	_ENDIF
.no_palette:
	bbs2	code,.indexed
	inc	frameptr
	_IFEQ
	  inc	frameptr+1
	_ENDIF
.noidx
	lda	(frameptr)
	beq	.done
	sta	color
	and	#$f
	sta	points

	ldx	#0
	ldy	#1
.getcoor
	lda	(frameptr),y
	iny
	sta	x1,x
	lda	(frameptr),y
	iny
	sta	y1,x
	inx
	cpx	points
	bne	.getcoor

	clc
	tya
	adc	frameptr
	sta	frameptr
	_IFCS
	  inc	frameptr+1
	_ENDIF

	jsr	poly
	bra	.noidx

.done
	inc	frameptr
	_IFEQ
	  inc	frameptr+1
	_ENDIF
	clc
	rts

.indexed
	lda	(frameptr),y
	tax
	sec
	tya
	adc	frameptr
	sta	.xcoord+1
	dey			; y = 0
	tya
	adc	frameptr+1
	sta	.xcoord+2

	clc
	txa
	adc	.xcoord+1
	sta	.ycoord+1
	tya
	adc	.xcoord+2
	sta	.ycoord+2
	txa
	adc	.ycoord+1
	sta	frameptr
	tya
	adc	.ycoord+2
	sta	frameptr+1
.drawidx
	lda	(frameptr)
	beq	.done

	ldy	#1
	sta	color
	and	#$f
	sta	temp
	sta	points
	sta	.smc1+1

.set_coord
	lda	(frameptr),y
	tax
.xcoord
	lda	$1100,x
	sta	x1-1,y
.ycoord
	lda	$2200,x
	sta	y1-1,y
	iny
	dec	temp
	bne	.set_coord

	jsr	poly

	sec			; points+1
.smc1	lda	#10
	adc	frameptr
	sta	frameptr
	bcc	.drawidx
	inc	frameptr+1
	bra	.drawidx

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

	LDAY	titleSCB
	jmp	_DrawSprite

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
	db " I",13
	db " C",13
	db " C",13
	db " C",13
	db " 2",13
	db " 0",13
	db " 0",13
	db " 0",0

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
 IF LZ4 = 1
	include "unlz4_fast.inc"
 ELSE
	include "untsc.inc"
 ENDIF
	include "abcmusic.inc"

pal:
	DP 000,40a,e0e,60c,208,a0e,80e,006,eee,419,83D,62B,A4A,217,115,FFF

chn1:
	db "X7 T10"
	db "z10"
	db "O4 V60 R20 H5 K2 "
	db "z12z12z12"
	db "|:15 E4E2E4E2:"
	db "|:18 E4E2E4E2:"
	db "|:18 E4E2E4E2:"
	db "|:18 E4E2E4E2:"
	db 0

chn2:	db "X1 T10 O3 V50 R50 H10"
	db "|:12 B2G2A2b2O2c2O3b2 a2d2g2a2b2a2 g2a2g2d2g2G2"
	db "|:12 B2G2A2b2O2c2O3b2 a2d2g2a2b2a2 g2a2g2d2g2G2:K10"
	db 0

chn3:
	db "X5I0 T10 O2 V50 R20 H4 K2"
	db "z10"
	db "z12z12z12"
	db "|:15z6:"
	db "H4 K2"
	;; 18
	db "G2g2g2g2g2g2 f2g2g2g2g2g2"
	db "e2g2g2d2g2g2 c2g2g2g2g2g2"
	db "c2f2B2e2A2d2 G2c2A2d2B2e2 A2d2G2c2F2d2 G2e2A2d2B2C2"
	db "A2B2G2A2F2G2 E2A2D2B2E2A2 F2d2G2e2A2d2 B2c2A2d2G2E2"
	db "A2d2G2c2F2d2 G2e2A2d2B2c2 A2d2G2d2A2d2"
	db "B4B2B4B8A4G2 G4F8  E4E4E4 F4F4F4B4B4A4"
	db "K1 H4 G12"
	db "|:18z12:"
	db "K2"
	;; 18
	db "G2g2g2g2g2g2 f2g2g2g2g2g2"
	db "e2g2g2d2g2g2 c2g2g2g2g2g2"
	db "c2f2B2e2A2d2 G2c2A2d2B2e2 A2d2G2c2F2d2 G2e2A2d2B2C2"
	db "A2B2G2A2F2G2 E2A2D2B2E2A2 F2d2G2e2A2d2 B2c2A2d2G2E2"
	db "A2d2G2c2F2d2 G2e2A2d2B2c2 A2d2G2d2A2d2"
	db "B4B2B4B8A4G2 G4F8  E4E4E4 F4F4F4B4B4A4"
	db "K1 H4 G12"
	db 0

chn4:
	db "X1I0 T10 O2 V30 R20 H4 K2"
	db "z10"
	db "z12z12z12"
	db "|:15z6:H4"
	db "K2"
	;; 18
	db "G2g2g2g2g2g2 f2g2g2g2g2g2"
	db "e2g2g2d2g2g2 c2g2g2g2g2g2"
	db "c2f2B2e2A2d2 G2c2A2d2B2e2 A2d2G2c2F2d2 G2e2A2d2B2C2"
	db "A2B2G2A2F2G2 E2A2D2B2E2A2 F2d2G2e2A2d2 B2c2A2d2G2E2"
	db "A2d2G2c2F2d2 G2e2A2d2B2c2 A2d2G2d2A2d2"
	db "B4B2B4B8A4G2 G4F8  E4E4E4 F4F4F4B4B4A4"
	db "K1 H4 G12"
	db "K2"
	;; 18
	db "G2g2g2g2g2g2 f2g2g2g2g2g2"
	db "e2g2g2d2g2g2 c2g2g2g2g2g2"
	db "c2f2B2e2A2d2 G2c2A2d2B2e2 A2d2G2c2F2d2 G2e2A2d2B2C2"
	db "A2B2G2A2F2G2 E2A2D2B2E2A2 F2d2G2e2A2d2 B2c2A2d2G2E2"
	db "A2d2G2c2F2d2 G2e2A2d2B2c2 A2d2G2d2A2d2"
	db "B4B2B4B8A4G2 G4F8  E4E4E4 F4F4F4B4B4A4"
	db 0


title:
	ibytes "title1.spr"

;;; ----------------------------------------
;;; Start song (all scores at the same time)
startSong:
	php
	sei
	lda #<chn1
	ldy #>chn1
	ldx #0
	jsr abc_set_score

	lda #<chn2
	ldy #>chn2
	ldx #1
	jsr abc_set_score

	lda #<chn3
	ldy #>chn3
	ldx #2
	jsr abc_set_score

	lda #<chn4
	ldy #>chn4
	ldx #3
	jsr abc_set_score
	plp
	rts
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

	jsr abc_init

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
end:
free	equ scene-init
	echo "init: %hinit"
	echo "end: %hend"
	echo "screen0:%Hscreen0"
	echo "screen1:%Hscreen1"
	echo "scene:%Hscene"
	echo "free:%Hfree"
 IFD LNX
 IF (end - Start) > SCENE_1ST_BLOCK*2048
	echo "Fix start block!!"
 ENDIF
 ENDIF
