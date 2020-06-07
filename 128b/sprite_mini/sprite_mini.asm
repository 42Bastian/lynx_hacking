***************
* Minimal Suzy setup for sprites (no tricks).
* 20 byte free.
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
	dec	$fda3
	ldx	#9-1
.mloop
	  ldy	SUZY_addr,x
	  lda	SUZY_data,x
          sta	$fc00,y
          dex
        bpl .mloop

	lda	#<plot_SCB	; Could be moved into SUZY_addr/data!
	sta	SCBNEXT
	lda	#>plot_SCB
	sta	SCBNEXT+1
	lda	#1
	STA	SPRGO		; start drawing

	STZ	SDONEACK
	STZ	CPUSLEEP
main
	bra	main
;;;------------------------------
	;; Writing low-byte in SUZY space clears highbyte!
SUZY_addr
	db $09,$08,$04,$06,$28,$2a,$83,$92,$90
SUZY_data
	db $20,$00,$00,$00,$7f,$7f,$f3,$00,$01
plot_SCB:
	db $01						;0
	dc.b SPRCTL1_LITERAL| SPRCTL1_DEPTH_SIZE_RELOAD ;1
	dc.b 0						;2
	dc.w 0						;3
	dc.w plot_data					;5
plot_x	dc.w 80						;7
plot_y	dc.w 51						;9
        dc.w $100					;11
        dc.w $100					;13
plot_color:						;15
	db	3

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
 IFND LNX
	;; Lynx rom clears to zero after boot loader!
	dc.b 0
 ENDIF
End:
size	set End-Start
free 	set 128-size

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree"
