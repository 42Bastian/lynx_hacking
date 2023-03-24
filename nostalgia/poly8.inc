****************
* Triangle
* (x1,y1),(x2,y2),(x3,y3)
* draw
*        A
*       /\
*      /  \
*     /    \
*  B /      \ B'
*    \       \
*     \_      \
*       \_     \
*         \_    \
*           \_   \
*             \_  \
*               \_ \
*                 \_\
*                     C
*
* two triangles/sprites : 1) ABB' 2) BB'C
*
* Same as triangle, but only 8bit coordinates
****************
triangle8__:
	lda color
triangle8::
	sta .tri_scb_color
	sta .tri_scb2_color
triangle8_:
*
* sort points
*
	ldx	x1
	ldy	y1
	lda	y2
	cpy	y2
	_IFCS			; y1 > y2 ?
	  stx	px2
	  sty	py2
	  sta	py1
	  ldx	x2
	  stx	px1
	  tay			; y = py1
	_ELSE
	  stx	px1
	  sty	py1
	  sta	py2
	  lda	x2
	  sta	px2
	_ENDIF
	lda	y3
	cpy	y3
	_IFCS			; py1 > y3
	  stx	px3
	  sty	py3
	  ldx	x3
	  stx	px1
	  sta	py1
	_ELSE
	  sta	py3
	  lda	x3
	  sta	px3
	_ENDIF
	ldy	py2
	cpy	py3
	_IFCS			; py2 > py3
	  ldx	px2
	  lda	py3
	  sty	py3
	  sta	py2
	  lda   px3
	  stx	px3
	  sta	px2
	_ENDIF

	MOVEB px3,.tri_scb2_x
	MOVEB py3,.tri_scb2_y
	MOVEB py1,.tri_scb_y
	MOVEB px1,.tri_scb_x

	ldy #-1			; prepare sign flag
	sec
	lda py2
	sbc py1
	_IFNE
	  inc
	_ENDIF
	tax
	sta .tri_scb_ysize+1
	lda reci_lo-1,x
	sta MATHE_C
	lda reci_hi-1,x
	sta MATHE_C+1

	sec
	lda px2
	sbc px1
	_IFNE
	  _IFCC
	    iny
	    eor #$ff
	    inc
	  _ENDIF
	  stz MATHE_E
	  sta MATHE_E+1
	  WAITSUZY
	  tya
	  _IFEQ
	    sec
	    sbc MATHE_A+2
	    tax
	    tya
	    sbc MATHE_A+3
	    dey
	  _ELSE
	    ldx MATHE_A+2
	    lda MATHE_A+3
	    _IFMI
	      lda #0
	      tax
	    _ENDIF
	  _ENDIF
	_ELSE
	  tax
	_ENDIF
	sta tiltAB+1
	stx tiltAB

****************
	sec
	lda py3
	sbc py1
	tax
	lda reci_lo,x

	sta MATHE_C
	lda reci_hi,x
	sta MATHE_C+1

	sec
	lda px3
	sbc px1
	_IFNE
	  _IFCC
	    iny
	    eor #$ff
	    inc
	  _ENDIF
	  stz MATHE_E
	  sta MATHE_E+1
	  WAITSUZY
	  tya
	  _IFEQ
	    sec
	    sbc MATHE_A+2
	    tax
	    tya
	    sbc MATHE_A+3
	    dey
	  _ELSE
	    ldx MATHE_A+2
	    lda MATHE_A+3
	    _IFMI
	      lda #0
	      tax
	    _ENDIF
	  _ENDIF
	_ELSE
	  tax
	_ENDIF
	sta tiltAC+1
	sta temp+1
	stx tiltAC
	stx temp

****************
	sec
	lda py3
	sbc py2
	sta .tri_scb2_ysize+1
	tax
	ora .tri_scb_ysize+1
	beq .exit

	lda reci_lo,x
	sta MATHE_C
	lda reci_hi,x
	sta MATHE_C+1

	sec
	lda px3
	sbc px2
	_IFNE
	  _IFCC
	    iny
	    eor #$ff
	    inc
	  _ENDIF
	  stz MATHE_E
	  sta MATHE_E+1
	  WAITSUZY
	  tya
	  _IFEQ
	    sec
	    sbc MATHE_A+2
	    tax
	    tya
	    sbc MATHE_A+3
	    dey
	  _ELSE
	    ldx MATHE_A+2
	    lda MATHE_A+3
	    _IFMI
	      lda #0
	      tax
	    _ENDIF
	  _ENDIF
	_ELSE
	  tax
	_ENDIF
	stx tiltBC
	sta tiltBC+1
****************
	CMPWS tiltAC,tiltAB
	_IFLT
	  SWAP tiltAB,tiltAC
	_ENDIF
	SUBW tiltAC,tiltAB,.tri_scb_stretch
	_IFMI
.exit
	  rts
	_ENDIF
	MOVE tiltAC,.tri_scb_tilt
****************
	CMPWS temp,tiltBC	; original tiltAC
	_IFLT
	  SWAP temp,tiltBC
	_ENDIF
	SUBW temp,tiltBC,.tri_scb2_stretch

	sec
	tya
	sbc tiltBC
	sta .tri_scb2_tilt
	tya
	sbc tiltBC+1
	sta .tri_scb2_tilt+1
****************
	LDAY .tri_scb
	ldx .tri_scb_ysize+1
	_IFEQ
	  inc .tri_scb2_ysize+1
	  LDAY .tri_scb2
	_ENDIF
_DrawSprite:		; <= called by main code to draw a sprite
	sta $fc10
	sty $fc11
	lda #1
	STA $FC91
	stz $fd90
.wait1	STZ $FD91
	bit $fc92
	bne .wait1
	STZ $FD90
	rts

**************************************************
.trieveron1	dc.b 0
.tri_scb	dc.b $c0,$80|$30,0
		dc.w .tri_scb2,.triimage
.tri_scb_x	dc.w 0
.tri_scb_y	dc.w 0
.tri_scb_xsize	dc.w $180
.tri_scb_ysize	dc.w $180
.tri_scb_stretch dc.w 0
.tri_scb_tilt	dc.w 0
.tri_scb_color	dc.b $f0

.trieveron2	dc.b 0
.tri_scb2	dc.b $d0,$80|$30,0
		dc.w 0,.triimage
.tri_scb2_x	dc.w 0
.tri_scb2_y	dc.w 0
.tri_scb2_xsize dc.w $180
.tri_scb2_ysize dc.w $180
.tri_scb2_stretch dc.w 0
.tri_scb2_tilt	dc.w 0
.tri_scb2_color dc.b $e0
.triimage	dc.b 2,$00,0

s		set 1
reci_lo:
	db 0
	REPT 159
	db   <((65535)/s)
s	set s+1
	ENDR
s		set 1
reci_hi:
	db 0
	REPT 159
	db   >((65535)/s)
s	set s+1
	ENDR