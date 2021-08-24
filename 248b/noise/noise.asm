***************
* Noise
* 5 byte free.
****************

	include <includes/hardware.inc>

;;; ROM sets this address
screen0	 equ $2000

	run	$200

 IFND LNX
	;; Setup needed if loaded via BLL/Handy
	lda	#8
	sta	$fff9
	sei
	lda	#$20
	stz	$fd94
	sta	$fd95
	stz	$fd50
	ldy	#2
	stz	0
	lda	#$e
	sta	$fdae
	ldx	#15
.init
	txa
	sta	$fda0,x
	stz	$fdb0,x
	dex
	bne	.init

	ldy	#8192/256
.clr
	stz	$2000,x
	inx
	bne	.clr
	inc	.clr+2
	dey
	bne	.clr
	stz	4
	lda	#$fa
	sta	4+1
	stz	$fd20
 ENDIF

Start::
	ldy	#9
.mloop
	  ldx	SUZY_addr-1,y
	  lda	SUZY_data-1,y
          sta	$fc00,x
          dey
        bne .mloop

	ldx	#16
.cloop
	  stz	$fda0-1,x
	  stz	$fdb0-1,x
	  dex
	bne	.cloop

//->	stz	$fd20
	lda	#$c0
	sta	$fd21
	lda	#$18|6
	sta	$fd25

//->	ldx	#0
//->	ldy	#0
again:
	lda	#<plot_SCB
	sta	$fc10
	lda	#>plot_SCB
	sta	$fc11

	lda	#1
	STA	SPRGO
	STZ	SDONEACK
.wait:
	STZ	CPUSLEEP
	;; Small sprite, so SUZE will finish quickly
//->	bit	SPRSYS
//->	bne	.wait

	lda	$fd23		;; LSFR Random Generator ;-)
	pha
	and	#8
	beq	next
inc_x:
	dec	plot_x
	beq	mirror_x
	lda	plot_x
	cmp	#159
	bne	next
mirror_x:
	lda	inc_x
	eor	#$20
	sta	inc_x
next:
	pla
	lsr
	bcc	nexty
inc_y:
	inc	plot_y
	beq	mirror_y
	lda	plot_y
	cmp	#102
	bne	nexty
mirror_y:
	lda	inc_y		;; self-mode code: INC ZP <=> DEC ZP
	eor	#$20
	sta	inc_y
	inc	plot_color
nexty:
	sty	plot_color
	dey
	bne	again
	dex
	beq	cycle
	bra	again
cycle::
	lda	#<noise_SCB
	sta	$fc10
	lda	#>noise_SCB
	sta	$fc11

	lda	#1
	STA	SPRGO
	STZ	SDONEACK
.waits:
	STZ	CPUSLEEP

	ldx	#$e		;; cycle only 15 colors
cycle_loop:

.wait
	ldy	$fd0a
	bne	.wait

	stz	$fda1,x
	stz	$fdb1,x
	dex
	bpl	.nowrap
	ldx	#$e
	inc	$fd20
.nowrap
	dec	$fda1,x
	dec	$fdb1,x
	bra	cycle_loop


draw_spr:

;;;------------------------------
SUZY_addr
	db $09,$08,$04,$06,$28,$2a,$83,$92,$90
SUZY_data
	db $20,$00,$00,$00,$7f,$7f,$f3,$24,$01

noise_SCB:
	dc.b SPRCTL0_NORMAL|SPRCTL0_2_COL
	dc.b SPRCTL1_LITERAL| SPRCTL1_DEPTH_SIZE_RELOAD ;1
	dc.b 0						;2
	dc.w 0						;3
	dc.w noise_data					;5
	dc.w 80-40					;7
	dc.w 51-12					;9
        dc.w $400					;11
        dc.w $400					;13
//->	dc.b $0f ;; save one byte, use pen 4
noise_data:

	dc.b 4,%10010011,%00111001,%10111000
	dc.b 4,%11010100,%10010010,%00100000
	dc.b 4,%10110100,%10010001,%00110000
	dc.b 4,%10010100,%10010000,%10100000
	dc.b 4,%10010011,%00111011,%00111000
	dc.b 0

plot_SCB:
	dc.b SPRCTL0_NORMAL|1|SPRCTL0_16_COL
	dc.b SPRCTL1_LITERAL| SPRCTL1_DEPTH_SIZE_RELOAD ;1
	dc.b 0						;2
	dc.w 0						;3
	dc.w plot_data					;5
plot_x	dc.w 2						;7
plot_y	dc.w 2						;9
        dc.w $100					;11
        dc.w $100					;13
plot_color:						;15
	dc.b $0f
plot_data:
	dc.b 2,$10
 IFND LNX
	;; Lynx rom clears to zero after boot loader!
	dc.b 0
 ENDIF
End:
size	set End-Start
free	set 249-size

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree"
