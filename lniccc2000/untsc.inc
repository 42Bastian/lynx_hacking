;; -*-asm-*-
;; depacker for TSCrunch, based on Antonio Savona's 6502 version.
;;
;; IN: dst - destination
;;

leave_early:
	ldy	#1
	rts
untsc::
	jsr	tsc_getbyte
	sta	optRun+1
untsc_cont:
entry2:
	dec	token_count
	beq	leave_early
	ldy	#0
	jsr	tsc_getbyte
	tax
	bmi	rleorlz
	cmp	#$20
	bcs	lz2
	tax
ts_delit_loop:
	jsr	tsc_getbyte
	sta	(dst),y
	iny
	dex
	bne	ts_delit_loop
	tya
	clc
updatezp:
	adc	dst
	sta	dst
	bcc	entry2
	inc	dst+1
	bra	entry2

rleorlz:
	and	#$7f
	lsr
	bcc	ts_delz
	// RLE
	beq	optRun

	tay
	tax			; save count
	jsr	tsc_getbyte
runStart:
	sta	(dst),y
ts_derle_loop:
	dey
	sta	(dst),y
	bne	ts_derle_loop
	txa
	bra	updatezp	; C = 1!
lz2:
	beq	done		; == $20
	ora	#$80
	adc	dst
	sta	lzput
	lda	dst+1
	sbc	#$0
	sta	lzput+1

	lda	(lzput)
	sta	(dst)
	iny			; y = 1
	lda	(lzput),y
	sta	(dst),y

	tya
	bra	updatezp	; C = 1!

	// LZ
ts_delz:
	tax
	jsr	tsc_getbyte
	sta	tstemp
	txa
	lsr
	sta	lzto+1
	lda	dst
	bcc	long
	sbc	tstemp
	sta	lzput
	lda	dst+1
	sbc	#$0
lz_put:
	sta	lzput+1

	lda	(lzput)
	sta	(dst)
ts_delz_loop:
	iny
	lda	(lzput),y
	sta	(dst),y
lzto:
	cpy	#0
	bne	ts_delz_loop
	tya
	bra	updatezp	; C = 1 !
optRun:
	lda	#255
	tax
	tay
	lda	#0
	bra	runStart
long:
	adc	tstemp
	sta	lzput
	php
	jsr	tsc_getbyte
	plp
	tax
	ora	#$80
	adc	dst+1
	cpx	#$80
	rol	lzto+1
	bra	lz_put
done:
	ldy	#0
	rts

tsc_getbyte
	lda	$fcb2
	inc	BlockByte
	beq	.9
	rts
.9
	inc	BlockByte+1
	beq	.10
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
