;-*-asm-*-
px1	equ	x0
px2	equ	x1
py1	equ	y0
py2	equ	y1

DrawLine::
	lda px2
	ldy py2
	cmp px1
	_IFCC
	  ldy px1
	  sta px1
	  sty px2
	  lda py2
	  ldy py1
	  sta py1
	  sty py2
	_ENDIF

	MOVEB px1,dl_scb_x
	MOVEB py1,dl_scb_y

	tya
	ldy #SPRCTL0_16_COL
	sec
	sbc py1
	_IFMI
	  eor #$ff
	  inc
	  ldy #SPRCTL0_16_COL|SPRCTL0_VFLIP
	_ENDIF
	inc
	sta dl_scb_ysize+1
	sta MATHE_B
//->	stz MATHE_A
	stz MATHE_A+2
	sec
	lda px2
	sbc px1
	inc
	sta MATHE_A+3
	sty dl_scb
	WAITSUZY
	MOVE MATHE_D+2,dl_scb_tilt
	inc
	sta dl_scb_xsize+1
	lda #<dl_scb
.exit
;;;------------------------------
;; Draw sprite
;; A - low byte of SCB
;; high byte common
draw_sprite
	sta	SCBNEXT
	lda	#>dl_scb
	sta	SCBNEXT+1
	STA	SPRGO		; start drawing
	STZ	SDONEACK
	STZ	CPUSLEEP
	rts

line_size	set .exit-DrawLine
	echo "Line: %Dline_size"
