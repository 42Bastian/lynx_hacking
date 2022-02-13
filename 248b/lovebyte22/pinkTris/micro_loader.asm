; micro loader
;
; Loads the next 256 bytes to $200.
; Register are preset like the ROM does

RCART_0	EQU $fcb2	; cart data register

	RUN    $0200

	txs

	; Copy loader onto stack
	ldx	#b9-b0+1
cpy:
	lda	b0-1,x		; copy loader
	pha
	dex
	bne	cpy
	ldy	#51+1		; already 51 bytes loaded from 1st block!
	bra	$200-(b9-b0)	; bra b0

	; From here copied onto stack
b0:
	lda	RCART_0
DST
	sta	$200-(51+1),y	; first byte goes to $200
	inx
	beq	b8
	iny
	bne	b0
	inc	$200-(b9-DST)+2; next dst page
	bra	b0
b8:
	txa
	ldx	#3
	txs
	tax
	ldy	#2
b9:
	; program is here at $200!

endofbl:

size	set endofbl-$200
free	set 49-size

	echo "Free %Dfree"
	IF free < 0
	echo "Size must be <= 50!"
	ENDIF

	; fill remaining space
	IF free > 0
	REPT	free
	dc.b	$42		; unused space shall not be 0!
	ENDR
	ENDIF
	dc.b 	$00		; end mark!
