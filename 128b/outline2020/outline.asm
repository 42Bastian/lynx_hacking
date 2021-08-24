***************
* Outline 2020 Demo
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
	stz	$fda3
	stz	$fdb3
 ENDIF

Start::
.loop
	lda	$fd0a
	asl
	sta	$fdb3

	ldx	 #12-1
.mloop
	  ldy	SUZY_addr,x
	  lda	SUZY_data,x
          sta	$fc00,y
          dex
        bpl .mloop

	STZ	$FD90
	STZ	$FD91

	inc	plot_szy
	inc	plot_szx
	bne	.loop

	inc	plot_szy+1
	inc	plot_szx+1
	lda	plot_szy+1
	cmp	#8
	bne	Start
	stz	plot_szy+1
	stz	plot_szx+1
	bra 	Start

	db $42
;;;------------------------------

SUZY_addr
	db $91,$09,$08,$11,$10,$04,$06,$28,$2a,$83,$92,$90
SUZY_data
	db $01,$20,$00,>plot_SCB,<plot_SCB,$00,$00,$7f,$7f,$f3,$00
plot_SCB:
	db $01	 // last byte of SUZY_data

//->	dc.b SPRCTL0_2_COL |SPRCTL0_BACKGROUND_NON_COLLIDABLE
	dc.b SPRCTL1_LITERAL| SPRCTL1_DEPTH_SIZE_RELOAD
	dc.b 0
	dc.w 0
	dc.w plot_data
plot_x	dc.w 80
plot_y	dc.w 51
plot_szx dc.w $100
plot_szy dc.w $100
plot_color:
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
//->	dc.b 0				// not needed, memory is cleared by ROM

	;; normal
//->	dc.b 5,%00110010,%10111010,%00111010,%01011100
//->	dc.b 5,%01001010,%10010010,%00010010,%01010000
//->	dc.b 5,%01001010,%10010010,%00010011,%01011100
//->	dc.b 5,%01001010,%10010010,%00010010,%11010000
//->	dc.b 5,%00110011,%00010011,%10111010,%01011100
//->	dc.b 0

End:
 IFND LNX
	dc.b 0
 ENDIF
size	set End-Start
free 	set 128-size

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree"
