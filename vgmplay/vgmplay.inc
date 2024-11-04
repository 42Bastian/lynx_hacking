;;;-*-asm-*-

streamHandler::
	lda RCART0 ;command
	asl
	sta command
	bcc skip_fill_mikey

	;filling mikey registers
	ldy RCART0 ;number of registers
.fm
	ldx RCART0 ;register
	lda RCART0 ;value
	sta $FD00,x
	dey
	bne .fm

skip_fill_mikey
	asl command
	bcc skip_fill_memory

skip_fill_memory
	asl 	command
	bcc 	skip_change_block

	lda 	RCART0 ;block number
	clc
	adc	#firstV2LSector
	jsr 	VGM_SelectBlock

skip_change_block
	asl command
	bcc skip_jsr

skip_jsr
	asl command
	bcs streamHandler
	rts

****************
* Select a block
****************
VGM_SelectBlock::
	pha
	lda _IOdat
	and #$fC
	tay
	ora #2
	tax
	pla
	SEC
	BRA SBL2
SLB0	BCC SLB1
	STX $FD8B
	CLC
SLB1	INX
	STX $FD87
	DEX
SBL2	STX $FD87
	ROL
	STY $FD8B
	BNE SLB0

	lda _IOdat
	sta $fd8b
.exit	RTS

echo	"Streamhandler: %H streamHandler"
