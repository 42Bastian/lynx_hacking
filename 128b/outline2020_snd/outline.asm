***************
* Outline 2020 Demo
* Enhanced with "sound"
* 1 byte free.
****************

	include <includes/hardware.inc>

;;; ROM sets this address
screen0	 equ $2000

 IFD LNX
	run	$200
 ELSE
	;; BLL loader is at $200, so move up
	run	$400
 ENDIF

 IFND LNX
	;; Setup needed if loaded via BLL/Handy
	lda	#8
	sta	$fff9
	cli
	lda	#$20
	stz	$fd94
	sta	$fd95
	stz 	$fd50
	ldy	#2
 ENDIF

Start::
	lda	#$98|2
	sta	$fd20
	sta	$fd25
	sty	plot_SCB+15
main::
	sty	plot_SCB+12
	sty	plot_SCB+14

	phy
.loop
	dec	$fda2
	inc	$fd24
	ldx	#11-1
.mloop
	  ldy	SUZY_addr,x
	  lda	SUZY_data,x
          sta	$fc00,y
          dex
        bpl .mloop

	STZ	$FD90
	STZ	$FD91

	inc	plot_SCB+11
	inc	plot_SCB+13
	bne	.loop
	ply

	iny
	cpy	#8
	bne	main
	ldy	#0
	bra	main
;;;------------------------------
plot_data:
	;; "OUTLINE"
	;; centered
	dc.b 3,%00010010,%11010000
	dc.b 3,%10111010,%01011100
	dc.b 1
	dc.b 3,%00010011,%01011100
	dc.b 3,%00010010,%01010000
	dc.b 3,%00111010,%01011100
	dc.b 1
	dc.b 3,%01001001,%01010010
	dc.b 3,%01001001,%01010010
	dc.b 3,%01011101,%01001100
	dc.b 1
	dc.b 3,%01001001,%01010010
	dc.b 3,%11001000,%11001100
	dc.b 0

SUZY_addr
	db $91,$09,$08,$11,$10,$04,$06,$28,$83,$92,$90
SUZY_data
	db $01,$20,$00,>plot_SCB,<plot_SCB,$00,$00,$7f,$f3,$00
plot_SCB:
	db $01	 // last byte of SUZY_data	; 0
	dc.b SPRCTL1_LITERAL| SPRCTL1_DEPTH_SIZE_RELOAD ;1
	dc.b 0						;2
	dc.w 0						;3
	dc.w plot_data					;5
plot_x	dc.w 80						;7
plot_y	dc.b 51						;9
	;; Lynx rom clears to zero after boot loader!
 if 0
plot_szx dc.w $100					;11
plot_szy dc.w $100					;13
plot_color:						;15
	db	3
 endif

End:
size	set End-Start
free 	set 128-size

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree"
