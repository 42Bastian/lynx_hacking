****************
** skywalk - a starpath remix
** Author: 42Bastian
** Party: SillyVenture 2025 SE
** Size: 481+17b loader
****************

	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/if_while.mac>

LOADER_SIZE    equ $11

SOUND	EQU 1

 BEGIN_ZP
scr	ds 3
ptr	ds 2
x1	ds 2
y1	ds 2
d0	ds 1
q	ds 1
frame	ds 1
x	ds 1
sndptr	ds 1
hbl	ds 1
sndstate ds 1
loopptr	ds 1
loopcnt	ds 5
 END_ZP

 IFND LNX
	run	$200-3
	jmp	bll_init
	ds	LOADER_SIZE
 ELSE
	run	$200+LOADER_SIZE
 ENDIF
;;; ----------------------------------------

plot_SCB	equ $100

plot_x		equ plot_SCB+7
plot_y		equ plot_SCB+9
x_size		equ plot_SCB+11
y_size		equ plot_SCB+13
plot_color 	equ plot_SCB+15

Start::
	jmp	skip_irq
irq::
	pha
	tsb	$fd80
	lda	$fd0a
	_IFNE
	  and	#$78
	  asl
	  eor	#$f0
	  sbc	#$30-1
	  sta	$fdb0
.leave
	  pla
	  stz	CPUSLEEP
	  rti
	_ENDIF
	dec hbl
	bne	.leave

	lda sndstate
	_IFEQ
	   stz $fd20
	   stz $fd28
	   dec sndstate
	   inc hbl
	   bra	.leave
	_ENDIF
	phx
	phy
.reread
	ldx sndptr
	ldy waitdata,x
	lda snddata,x

	_IFMI
	  inc
	  _IFEQ			; -1
	    txa
	    ldx	loopptr
	    dec	loopcnt,x
	    _IFEQ
	      dec loopptr
	    _ELSE
	      tya
	    _ENDIF
.next
	    inc
	    sta	sndptr
	    bra	.reread
	  _ENDIF
	  inc
	  _IFEQ			; -2
	    txa
	    inc loopptr
	    ldx	loopptr
	    sty loopcnt,x
	    bra	.next
	  _ENDIF
	     stz sndptr
	     bra .reread
	_ENDIF
	_IFNE
	  sta $fd24
	  asl
	  sta $fd24+8
	  lda #$20
	  sta $fd20
	  sta $fd28
	_ENDIF
	sty hbl
	inc sndptr
	stz sndstate
	ply
	plx
	pla
	rti

skip_irq::
	ldx	#50
.stars
	  stz	2,x
	  stx	ptr
	  lda	$210,x
	  and	#$1f
	  ora	#$80
	  sta	ptr+1
	  lda	#$e0
	  sta	(ptr)
	  smb6	ptr+1
	  sta	(ptr)
	  dey
	  dex
	bpl	.stars

	ldx	#8
	stx	$fff9		; map vector to RAM

	ldy	#2
	sty	$ffff
	lda	#<irq
	sta	$fffe

	sty	0		; plot data size
.mloop
	  ldy	SUZY_addr-1,x
	  lda	SUZY_data-1,x
	  sta	$fc00,y
	  dex
	bne	.mloop

	txs

	lda	#SPRCTL0_BACKGROUND_NON_COLLIDABLE|SPRCTL0_2_COL
	pha

	lda	#SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD|SPRCTL1_DRAW_LEFT
	sta	$101

	ldx	#15
	lda	#$ff
.col
	  stz	102,x
	  txa
	  sta	$fdb0,x
	  asl
	  sta	$fda0,x
	  dex
	bpl	.col

	lda	#$18|3
	sta	$fd25
	sta	$fd25+8
	lda	#$22
	sta	$fd21
	sta	$fd21+8

	lda	#$80
	sta	hbl
	sta	1		; plot data value
	tsb	$fd01
	pha			; save display address

	cli
main::
	lda	hbl
.wait	cmp	hbl
	bne	.wait

	pla
	sta     $fd95		; display
	eor     #$40
	sta     $fc09		; render
	pha

	ldy	#100
.loopy:
	sty	plot_y

	lda	#$2
	sta	x_size+1
	sta	y_size+1

	lda	#80
.loopx:
	pha
	asl
	sta	d0
	sta	x1
	sta	plot_x

	;; y1 = y
	sty	y1
	stz	y1+1

	;; q = 2*frame (for speed reason)
	lda	frame
	asl
	sta	q
	lda	#0		; clear x1+1
	tax			; clear D0+1
.rc
	sta	x1+1
	ora	y1+1
	and	q
	cmp	#16
	bcs	.leave0

	inc	q

	;; y1 += y
	tya
//->	clc			; is clear from above
	adc	y1
	sta	y1
	_IFCS
	  inc	y1+1
	  clc
	_ENDIF

	;; d0 -= 2
	lda	d0
	sbc	#1
	sta	d0
	_IFCC
	  dex			; D0+1
	_ENDIF

	;; x1 += d0
//->	clc
	adc	x1
	sta	x1
	txa
	adc	x1+1
	bpl	.rc

.leave_sky
	inc	x_size+1	; => 3
	ldx	#0
	pla
	phx			; quit x loop
	bra	.leave1
.leave0
	_IFEQ
	  inc
	_ENDIF
	tax
.leave1
	stx	plot_color
	;; ----------------------------------------
	stz	SCBNEXT
	lda	#>plot_SCB
	sta	SCBNEXT+1
	STA	SPRGO		; start drawing
	STZ	SDONEACK
	STZ	CPUSLEEP
	;; ----------------------------------------
	pla
	dec
	bpl	.loopx
	dey
	dey
	bpl	.loopy

	inc	frame
	jmp	main

;;; 16 per frame

NOTELEN	EQU 6
N_A	EQU 71
N_B	EQU 64
N_D	EQU 53
N_E	EQU 47

snddata:
	dc.b -2,N_B,-1		; l1
	dc.b 0
	dc.b N_D,0

	dc.b -2,N_B,-1		; l2

	dc.b 0

	dc.b -2			; l3
	dc.b -2,N_B,-1		; l4
	dc.b 0
	dc.b -1

	dc.b -2,N_B,-1		; l5
	dc.b 0

	dc.b -2			; l56 2
	dc.b -2,N_E,-1,0
	dc.b -2,N_D,-1,0
	dc.b 0
	dc.b N_A,N_A

	dc.b -2			;
	dc.b -2,N_B,-1		;
	dc.b -2,N_B,-1		;
	dc.b N_E,N_E
	dc.b -1			;
	dc.b -1

	dc.b 0
	dc.b -3

waitdata:
.l1	dc.b 5,NOTELEN,.l1-waitdata

	dc.b NOTELEN*22

	dc.b NOTELEN*2,NOTELEN*3

.l2	dc.b 5,NOTELEN,.l2-waitdata

	dc.b NOTELEN*27

.l3	dc.b 4
.l4	dc.b 5,NOTELEN,.l4-waitdata
	dc.b NOTELEN*3
	dc.b .l3-waitdata

.l5	dc.b 37,NOTELEN,.l5-waitdata
	dc.b NOTELEN

.l56	dc.b 2
.l6	dc.b 7,NOTELEN,.l6-waitdata,NOTELEN
.l7	dc.b 7,NOTELEN,.l7-waitdata,NOTELEN
	dc.b NOTELEN
	dc.b NOTELEN, NOTELEN

.l9	dc.b 3
.l10	dc.b 5,NOTELEN,.l10-waitdata
.l11	dc.b 7,NOTELEN,.l11-waitdata
	dc.b NOTELEN, NOTELEN
	dc.b .l9-waitdata
	dc.b .l56-waitdata,NOTELEN

	dc.b 100
	dc.b 0

	;; Writing low-byte in SUZY space clears highbyte!
SUZY_addr
	db $08,$04,$06,$83,$92,$90,$28,$2a
SUZY_data
	db $00,$00,$00,$f3,$20,$01 ;,any,any
End:
;;;------------------------------

size	set End-Start
free	set 512-size-LOADER_SIZE

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF
;;; ----------------------------------------------------------------------
 IFND LNX
	include "bll_init.inc"
 ENDIF
	echo "Size:%dsize  Free:%dfree"
