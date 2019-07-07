****************
*
* chained_scbs.asm
* July 2019
*
* Show difference between drawing 102 sprites as chained and as single SBCs.
*
* Handy:   chained: 17ms  unchained 19ms
* Lynx II: chained: 11ms, unchained 14ms


DEBUG	set 1
Baudrate	set 62500

_1000HZ_TIMER	set 7

IRQ_SWITCHBUF_USR set 1

	include <macros\hardware.asm>
****************
	MACRO DoSWITCH
	dec SWITCHFlag
.\wait_vbl	bit SWITCHFlag
	bmi .\wait_vbl
	ENDM

	MACRO NEG
	sec
	tya
	sbc \0
	sta \0
	tya
	sbc 1+\0
	sta 1+\0
	ENDM

	MACRO SINUS
	ldx \0
	lda SinTab.Lo,x
	sta \1
	lda SinTab.Hi,x
	sta \1+1
	ENDM

	MACRO COSINUS
	clc
	lda \0
	adc #64
	tax
	lda SinTab.Lo,x
	sta \1
	lda SinTab.Hi,x
	sta \1+1
	ENDM

****************
* macros
	include <macros/help.mac>
	include <macros/if_while.mac>
	include <macros/font.mac>
	include <macros/window.mac>
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
	include <vardefs/window.var>
	include <vardefs/mikey.var>
	include <vardefs/suzy.var>
	include <vardefs/irq.var>
	include <vardefs/newkey.var>
	include <vardefs/serial.var>
	include <vardefs/1000Hz.var>
****************************************************

 BEGIN_ZP
poly_color	ds 1
ptr1		ds 2
counter		ds 1
flag		ds 1
winkel		ds 1
winkel_nk	ds 1  ; Nachkomma
winkel_add1	ds 1
amplitude	ds 1
Y		ds 1
frame_counter	ds 1
Xoffset		ds 1
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
 END_MEM
	run LOMEM
ECHO "START :%HLOMEM ZP : %HNEXT_ZP"
Start::	sei
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
	lda #$E0
	sta winkel_add1
	stz _1000Hz
	stz _1000Hz+1
	stz Y
again::
 IF 1
	jsr MakeChainedSCBs
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
		dec $fda0
	  stz _1000Hz
	  inc counter
	bne .loop
	dec frame_counter
	bne .loop
 ENDIF
x::
	lda #1
	sta frame_counter
	pha
	jsr  MakeSCBs
.loop
	  jsr _cls
	  jsr DrawSCBs4
	stz $fda0
	  stz CurrX
	  lda _1000Hz
	  jsr PrintHex
	  DoSWITCH
	dec $fda0
	  stz _1000Hz
	  inc counter
	bne .loop
	dec frame_counter
	bne .loop

	jmp again

copyPic::
	MOVEI piggy,.src+1	; Adresse des Bildes
	MOVE ScreenBase,.dst+1
	ldy	#0
	ldx	#32
.src
	lda	piggy,y
.dst
	sta	screen0,y
	iny
	bne	.src
	inc	.src+2
	inc	.dst+2
	dex
	bne	.src
	rts


****************
VBL::
	inc winkel
	jsr Keyboard
	IRQ_SWITCHBUF
	END_IRQ
****************
DrawSCBs5::
 IF 1
	ldy #101
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

	  lda scbtab,y
	  sta ptr
	  lda scbtab+102,y
	  sta ptr+1

	  clc
	  lda $fc61
	  adc Xoffset
	  sta (ptr)
	  phy
	  ldy #1
	  lda Xoffset+1
	  adc $fc62
	  sta (ptr),y
	  ply

	  clc
	  lda winkel_nk
	  adc winkel_add1
	  sta winkel_nk
	  bcc	.noc
	   inx
.noc
	  dey
	bpl .loop
	pla
	sta winkel_nk
	pla
	sta winkel
 ENDIF
	lda #<SCB0
	ldy #>SCB0
	jsr DrawSprite
	rts

DrawSCBs4::
	ldy #101
	ldx winkel
	stz flag
	lda Y
	sta SCBy
	stz SCBy+1
	beq .cont0
	stz winkel
	ldx #0
.cont0	lda winkel
	pha
	lda winkel_nk
	pha
.loop	  lda scbtab,y
	  sta SCBDATA+2
	  lda scbtab+160,y
	  sta SCBDATA+3
 IF 1
	  lda amplitude
	  sta $fc52
	  stz $fc53

	  lda SinTab.Lo,x
	  sta $fc54
	  lda SinTab.Hi,x
	  sta $fc55
.wait	  bit SPRSYS
	  bmi .wait
	  clc
	  lda $fc61
	  adc Xoffset
	  sta SCBx
	  lda Xoffset+1
	  adc $fc62
	  sta SCBx+1
	  clc
	  lda winkel_nk
	  adc winkel_add1
	  sta winkel_nk
	  lda winkel
	  adc #0
	  sta winkel
	  tax
 ENDIF
	  phy
	  lda #<SCB
	  ldy #>SCB
	  jsr DrawSprite
	  ply
	  inc SCBy
	  lda SCBy
	  cmp #102
	  beq .exit
	  dey
	bpl .loop
.exit
	pla
	sta winkel_nk
	pla
	sta winkel
	rts
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

	MOVEI piggy-1,ptr	; Adresse des Bildes
	MOVEI scbdata,ptr1	; aubereitetes Bild
	MOVEI scbs,ptr2
	ldx #0
.loop
	lda	#SPRCTL0_16_COL|SPRCTL0_BACKGROUND_SHADOW
	sta	(ptr2)
	ldy	#1
	lda	#SPRCTL1_LITERAL|SPRCTL1_PALETTE_NO_RELOAD
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
	lda	ptr1
	sta	(ptr2),y
	lda	ptr1+1
	iny
	sta	(ptr2),y

	lda	#0	; x
	iny
	sta	(ptr2),y
	iny
	sta	(ptr2),y

	txa
	iny
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

	pla
	sta	ptr2+1
	pla
	sta	ptr2
	lda	#82
	sta	(ptr1)
	ldy	#1
.loop1	  lda	(ptr),y
	  sta	(ptr1),y
	  iny
	  cpy	#81
	bne	.loop1
	lda	#0
	sta	(ptr1),y
	iny
	sta	(ptr1),y
	clc
	lda	ptr1
	adc	#83
	sta	ptr1
	bcc	.cont0
	  inc	ptr1+1
.cont0	clc
	lda	ptr
	adc	#80
	sta	ptr
	bcc	.cont1
	  inc	ptr+1
.cont1	inx
	cpx	#102
	beq	.exit
	jmp	.loop
.exit
	sec
	lda	ptr2
	sbc	#11-5
	sta	ptr2
	lda	ptr2+1
	sbc	#0
	sta	ptr2+1
	lda	#0
	sta	(ptr2)
	ldy	#1
	sta	(ptr2),y
	rts
SCB0
	dc.b SPRCTL0_16_COL|SPRCTL0_BACKGROUND_SHADOW
	dc.b SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD
	dc.b 0
	dc.w scbs	; next
	dc.w SCB0_data	; data
	dc.w 0		; x
	dc.w -1		; y
	dc.w $100,$100	; size
	dc.b $01,$23,$45,$67,$89,$AB,$CD,$EF
SCB0_data:
	dc.b 2,0,0

MakeSCBs::
	MOVEI piggy-1,ptr	; Adresse des Bildes
	MOVEI scbdata,ptr1	; aubereitetes Bild
	ldx #0
.loop	  lda ptr1
	  sta scbtab,x
	  sta SCBDATA+2
	  lda ptr1+1
	  sta scbtab+160,x
	  sta SCBDATA+3
	  lda #82
	  sta (ptr1)
	  ldy #1
.loop1	    lda (ptr),y
	    sta (ptr1),y
	    iny
	    cpy #81
	  bne .loop1
	  lda #0
	  sta (ptr1),y
	  iny
	  sta (ptr1),y
	  clc
	  lda ptr1
	  adc #83
	  sta ptr1
	  bcc .cont0
	    inc ptr1+1
.cont0	  clc
	  lda ptr
	  adc #80
	  sta ptr
	  bcc .cont1
	    inc ptr+1
.cont1	  inx
	cpx #102
	bne .loop
	rts

SCB	dc.b $c0,$90,$00
SCBDATA	dc.w 0,0
SCBx	dc.w 0
SCBy	dc.w 0
SCBsizex
	dc.w $100,$100
	dc.b $01,$23,$45,$67,$89,$AB,$CD,$EF
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
piggy
	ibytes <etc/phobyx1.o>

pal  DP 000,574,434,555,656,799,A9A,BCC,DCD,EFF,FAF,695,9B7,7A6,AAB,AC9
