***************
* Minimal Suzy setup for sprites.
* 0 byte free.
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
	lda	#$ff
	sta	$fda2
	sta	$fdb2
	ldy	#2
 ENDIF

Start::
	STZ	SDONEACK
	ldx	#10-1
.mloop
	  ldy	SUZY_addr,x
	  lda	SUZY_data,x
          sta	$fc00,y
          dex
        bpl .mloop
	STZ	CPUSLEEP
main
//->	bra	main
;;;------------------------------
	;; Writing low-byte in SUZY space clears highbyte!
SUZY_addr
	db SPRGO-$FC00,SCBNEXT-$FC00+1,SCBNEXT-$FC00,$09,$08,$28,$2a,$83,$92,$90
SUZY_data
	db 1,>plot_SCB,<plot_SCB,$20,$00,$7f,$7f,$f3,$00
plot_SCB:
	db $01						;0
	dc.b SPRCTL1_LITERAL| SPRCTL1_DEPTH_SIZE_RELOAD ;1
	dc.b 0						;2
	dc.w 0						;3
	dc.w plot_data					;5
plot_x	dc.w 80-14					;7
plot_y	dc.w 47						;9
        dc.w $400					;11
        dc.w $400					;13
plot_color:						;15

plot_data:
	dc.b 2,%01101100
	dc.b 2,%11111110
	dc.b 2,%01111100
	dc.b 2,%00111000
	dc.b 2,%00010000
End:
 IFND LNX
	;; Lynx rom clears to zero after boot loader!
	dc.b 0
 ENDIF
size	set End-Start
free 	set 64-size

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree"
