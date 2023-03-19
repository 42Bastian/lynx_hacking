;;; in:
;;; ZP
;;; src
;;; dst
;;; A:Y packed length

unlz4::
	jsr	lz4_getbyte0
 IFND LNX
	eor	#$ff
 ENDIF
	sta	lz4_src_e
	jsr	lz4_getbyte0
 IFND LNX
	eor	#$ff
 ENDIF
	sta	lz4_src_e+1
unlz4_cont:
.token
	dec	token_count
	bne	.token2
	ldy	#1
	rts
.token2:
	jsr	lz4_getbyte
	sta	.smc+1
	lsr
	lsr
	lsr
	lsr
	beq	.match
	jsr	lz4_getlen
.litloop
	jsr	lz4_getbyte
	sta	(dst),y
	iny
	beq	.incptrlit
.21
	inx
	bne	.litloop
	inc	lz4_tmp
	bne	.litloop

	clc
	tya
	adc	dst
	sta	dst
	bcc	.match
	inc	dst+1
.match
	jsr	lz4_getbyte
	tax
	jsr	lz4_getbyte
	tay
	clc
	txa
	sbc	dst
	eor	#$ff
	sta	lz4_ptr
	tya
	sbc	dst+1
	eor	#$ff
	sta	lz4_ptr+1
.smc
	lda	#10
	and	#15
	jsr	lz4_getlen
	sec
	txa
	sbc	#4
	tax
	bcs	.1
	dec	lz4_tmp
.1
.matchloop
	lda	(lz4_ptr),y
	sta	(dst),y
	iny
	beq	.incptr
.2
	inx
	bne	.matchloop
	inc	lz4_tmp
	bne	.matchloop
	clc
	tya
	adc	dst
	sta	dst
	bcc	.token
	inc	dst+1
	bra	.token

.incptr
	inc	lz4_ptr+1
	inc	dst+1
	bra	.2
.incptrlit
	inc	dst+1
	bra	.21

lz4_getlen
	ldy	#$ff
	cmp	#15
	bne	.noext
	sta	lz4_tmp
.loop
	jsr	lz4_getbyte
	cmp	#$ff
	beq	.33
	clc
	adc	lz4_tmp
	bcc	.3
	dey
.3
.noext
	eor	#$ff
	tax
	inx
	bne	.4
	iny
.4
	sty	lz4_tmp
	ldy	#0
	rts

.33
	dec	lz4_tmp
	dey
	bra	.loop

lz4_getbyte::
	inc	lz4_src_e
	beq	.2
lz4_getbyte0
	lda	$fcb2
	inc	BlockByte
	beq	.9
	rts
.9
	inc	BlockByte+1
	beq	.10
	rts

.2
	inc	lz4_src_e+1
	beq	.99
	lda	$fcb2
	inc	BlockByte
	beq	.9
	rts
.99

	pla
	pla
	ldy	#0
	rts

.10
****************
* Select a block
****************
SelectBlock
	pha
	phx
	phy
	lda CurrBlock
	inc CurrBlock
	ldx #2
	ldy #3
	SEC
	BRA .SBL2
.SLB0
	STX $FD8B
	CLC
.SLB1
	STY $FD87
.SBL2
	STX $FD87
	ROL
	STZ $FD8B
	BEQ .exit
	BCS .SLB0
	BRA .SLB1
.exit
	lda _IOdat
	sta $fd8b
	stz BlockByte
	lda #$100-(>BlockSize)
	sta BlockByte+1

	ply
	plx
	pla
	RTS
