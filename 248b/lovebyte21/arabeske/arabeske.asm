***************
* Arabeske - 128 bytes intro
* (c) 2021 42Bastian
****************

	include <includes/hardware.inc>
	include <macros/help.mac>

;;; ROM sets this address
screen0	 equ $2000

 BEGIN_ZP
x_add	ds 1			; ROM clears it
y_add	ds 1			; ROM clears it
 END_ZP

	run	$200

 IFND LNX
	;; Setup needed if loaded via BLL/Handy
	lda	#8
	sta	$fff9
	cli
	lda	#$20
	stz	$fd94
	sta	$fd95
	stz	$fd50
	stz	x_add
	stz	y_add
	ldy	#2
	lda	#$ff
	sta	$fda2
	sta	$fdb2
 ENDIF

Start::
	ldx	#9-1
.mloop
	  ldy	SUZY_addr,x
	  lda	SUZY_data,x
          sta	$fc00,y
          dex
        bpl .mloop

	inc	x_add		; == 1
	inc	y_add		; == 1
again
.0
	lda	$fd0a		; line counter
	sta	$fda2		; GREEN2
	bne	.0

	lda	#<plot_SCB	; Could be moved into SUZY_addr/data!
	sta	SCBNEXT
	lda	#>plot_SCB
	sta	SCBNEXT+1
	lda	#1
	STA	SPRGO		; start drawing

	STZ	SDONEACK
.WAIT	STZ	CPUSLEEP
;;->	bit	SPRSYS		; no need to wait, as no interrupts are used
;;->	bne	.WAIT

	clc
	lda	x_add
	adc	plot_x
	sta	plot_x
	beq	.revx

	cmp	#159
	bne	.1
.revx
	lda	x_add
	eor	#$ff
	inc
	sta	x_add
.1

;;->	clc			; C is always clear
	lda	y_add
	adc	plot_y
	sta	plot_y
	beq	.revy
	cmp	#101
	bne	again
.revy:
	lda	y_add
	eor	#$ff
	inc
	sta	y_add
	bra	again
;;;------------------------------
	;; Writing low-byte in SUZY space clears highbyte!
SUZY_addr
	db $09,$08,$04,$06,$28,$2a,$83,$92,$90
SUZY_data
	db $20,$00,$00,$00,$7f,$7f,$f3,$00
plot_SCB:
	db $01					; also last of SUZY_data!
	dc.b SPRCTL1_LITERAL| SPRCTL1_DEPTH_SIZE_RELOAD
	dc.b 0
	dc.w 0
	dc.w plot_data
plot_x	dc.w 80
plot_y	dc.w 51
        dc.w $100
        dc.w $100
plot_color:
;;->	db	3		; use first byte of plot_data as color index

plot_data:
	dc.b	2,%00101100

 IFND LNX
	;; Lynx rom clears to zero after boot loader!
	dc.b 0,0
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
