****************
*
* chained_scbs.asm
*
* (c) 42Bastian Schick
*
* July 2019
*


DEBUG	set 1
Baudrate	set 62500

_1000HZ_TIMER	set 7

IRQ_SWITCHBUF_USR set 1

	include <includes\hardware.inc>
****************
	MACRO DoSWITCH
	dec SWITCHFlag
.\wait_vbl	bit SWITCHFlag
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
counter		ds 1
winkel		ds 1
winkel_nk	ds 1  ; Nachkomma
winkel_add1	ds 1
amplitude	ds 1
frame_counter	ds 1
x	ds 2
y	ds 2
tmp	ds 1
*********************
 END_ZP

 BEGIN_MEM
irq_vektoren	ds 16
		ALIGN 4
screen0		ds SCREEN.LEN
screen1		ds SCREEN.LEN
scbdata		ds SCREEN.LEN+102*3
scbtab		ds 102
		ds 102
scbs		ds 102*15
scbx		ds 100
scby		ds 100
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
	jsr Init1000Hz
	FRAMERATE 60
	jsr InitComLynx
	SETIRQ 2,VBL
	SCRBASE screen0,screen1
	SET_MINMAX 0,0,160,102

	lda #$c0
	ora _SPRSYS
	sta SPRSYS
	sta _SPRSYS

	stz _1000Hz
	stz _1000Hz+1
	stz _1000Hz+2
	cli
	lda #20
	sta amplitude
	stz counter
	stz winkel
	lda #$f0
	sta winkel_add1
	stz _1000Hz
	stz _1000Hz+1
	jsr MakeChainedSCBs
again::
 IF 1
	lda #1
	sta frame_counter
	pha
.loop
	  jsr _cls
	  jsr DrawSCBs5
	stz $fda0
	  stz CurrX
	  lda _1000Hz
	  jsr PrintHex
	  DoSWITCH
//->	  dec $fda0
	  stz _1000Hz
	  inc counter
	bne .loop
	dec frame_counter
	bne .loop
 ENDIF

	jmp again
****************
VBL::
	inc winkel
	jsr Keyboard
	IRQ_SWITCHBUF
	END_IRQ
****************
DrawSCBs5::
 IF 1
	ldy #0
	ldx winkel
	phx
	lda winkel_nk
	pha
.loop
	  lda amplitude
	  sta $fc52
	  stz $fc53

	  lda SinTab.Lo,x
	  sta $fc54
	  lda SinTab.Hi,x
	  sta $fc55
.wait	  bit SPRSYS
	  bmi .wait

	  MOVE $fc61,x
	  phx
	  lda #10
	sta tmp
.loopx
	  lda scbtab,y
	  sta ptr
	  lda scbtab+102,y
	  sta ptr+1
 IF 1
	  phy
	  clc
	  lda 	x
	  adc	scbx,y
	  sta 	(ptr)
	  ldy	#1
	  lda	x+1
	  adc	#0
	  sta	(ptr),y
	  ply
 ENDIF
 IF 1
	  lda SinTab.Lo,x
	  sta $fc54
	  lda SinTab.Hi,x
	  sta $fc55
.wait1	  bit SPRSYS
	  bmi .wait1

	  phy
	  clc
	  lda 	$fc61
//->	  adc (ptr)
//->	  sta (ptr)
	  adc	scby,y
	  ldy	#2
	  sta 	(ptr),y
	  iny
	  lda	$fc62
//->	  ldy #1
//->	  adc (ptr),y
	  adc	#0
	  sta	(ptr),y
	  ply
	txa
	adc #4
	tax
//->	  inx
//->	inx
 ENDIF
	  iny
	  dec tmp
	bne .loopx
	plx
	  clc
	  lda winkel_nk
	  adc winkel_add1
	  sta winkel_nk
	  bcc	.noc
	   inx
.noc
	cpy #100
	beq	.exit
	jmp .loop
.exit
	pla
	sta winkel_nk
	pla
	sta winkel
 ENDIF
	lda #<SCB0
	ldy #>SCB0
	jmp DrawSprite

****************
_cls::	lda #<clsSCB
	ldy #>clsSCB
	jmp DrawSprite

clsSCB	dc.b $0,$10,0
	dc.w 0,clsDATA
	dc.w 0,0
	dc.w $100*10,$100*102
clsCOLOR
	dc.b 0
clsDATA
	dc.b 2,%01111100
	dc.b 0

MakeChainedSCBs::
	MOVEI scbs,ptr2

	stz	y
	lda	#1
	sta	x
	ldx 	#0
.loop
	lda	#SPRCTL0_16_COL|SPRCTL0_BACKGROUND_SHADOW
	sta	(ptr2)
	ldy	#1
	lda	#SPRCTL1_PALETTE_NO_RELOAD
	sta	(ptr2),y
	iny
	lda	#0
	sta	(ptr2),y

	clc		; nxt
	lda	ptr2
	adc	#11
	iny
	pha
	sta	(ptr2),y
	lda	#0
	adc	ptr2+1
	iny
	pha
	sta	(ptr2),y

	iny		; data
	lda	sprite_addr_lo,x
	sta	(ptr2),y
	lda	sprite_addr_hi,x
	iny
	sta	(ptr2),y

	lda	x
	iny
	sta	(ptr2),y
	sta	scbx,x
	iny
	clc
	adc	#16
	sta	x
	lda 	#0
	sta	(ptr2),y

	lda	y
	iny
	sta	scby,x
	sta	(ptr2),y	; y
	lda	#0
	iny
	sta	(ptr2),y

	lda	#0
	iny
	sta	(ptr2),y
	iny
	iny
	sta	(ptr2),y
	iny
	phy
	lda	#1
	sta	(ptr2),y
	dey
	dey
	sta	(ptr2),y
	ply
	clc
	lda	ptr2
	adc	#7
	sta	scbtab,x
	lda	ptr2+1
	adc	#0
	sta	scbtab+102,x

	MOVE	ptr2,ptr
	pla
	sta	ptr2+1
	pla
	sta	ptr2

	inx
	lda	x
	cmp	#161
	bne	.toloop
	lda 	#1
	sta	x
	lda	y
	clc
	adc	#10
	sta	y
	cmp	#100
	beq	.exit
.toloop
	jmp	.loop
.exit
	ldy	#4
	lda	#0
	sta	(ptr),y
	rts
SCB0
	dc.b SPRCTL0_16_COL|SPRCTL0_BACKGROUND_SHADOW
	dc.b SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD
	dc.b 0
	dc.w scbs	; next
	dc.w SCB0_data	; data
	dc.w 0		; x
	dc.w -1		; y
	dc.w $f0,$f0	; size
	dc.b $01,$23,$45,$67,$89,$AB,$CD,$EF
SCB0_data:
	dc.b 2,0,0

****************
PrintHex::
	phx
	pha
	lsr
	lsr
	lsr
	lsr
	tax
	lda digits,x
	jsr PrintChar
	pla
	and #$f
	tax
	lda digits,x
	jsr PrintChar
	plx
	rts

digits
	db "0123456789ABCDEF"
****************
* Sinus-Tabelle
* 8Bit Nachkomma
****************
SinTab.Lo
	ibytes <bin/sintab_8.o>
SinTab.Hi equ SinTab.Lo+256
***************************************************

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
	align 2
	include "sprites/sprites.inc"
	include "sprites/spriteaddrlo.inc"
	include "sprites/spriteaddrhi.inc"

pal  DP 000,574,434,555,656,799,A9A,BCC,DCD,EFF,FAF,695,9B7,7A6,AAB,AC9
