***************
* LynxBeat An UPN interpreter for ByteBeat code
* 6 bytes free, 39Bytes for ByteBeat.
****************

	include <includes/hardware.inc>
	include <macros/help.mac>
	include <macros/suzy.mac>

	;; If not enabled, counter runs with 7280Hz
HAVE_8000Hz EQU 1

//->HAVE_SWAP EQU 1
//->HAVE_DUB EQU 1
;;; ROM sets this address

screen0	 equ $2000

 BEGIN_ZP
t	ds 2
t_latch ds 2
dummy	ds 1
pc	ds 2
tmp	ds 4
 END_ZP

stack	equ $c0

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
	ldy	#2
	stz	$fd50
	lda	#10
	sta	t
	lda	#2
	sta	6
 ENDIF

	;; LynxBeat commands
	;; Each command is the low-byte of the routine, therefore
	;; all commands must be in a single page!

	MACRO BB_T
	dc.b <bb_t
	ENDM

	MACRO BB_AND
	dc.b <bb_and
	ENDM

	MACRO BB_OR
	dc.b <bb_or
	ENDM

	MACRO BB_EOR
	dc.b <bb_eor
	ENDM

	MACRO BB_ADD
	dc.b <bb_add
	ENDM

	MACRO BB_SUB
	dc.b <bb_sub
	ENDM

	MACRO BB_SHL
	dc.b <bb_shl
	ENDM

	MACRO BB_SHR
	dc.b <bb_shr
	ENDM

	MACRO BB_PUSH
	if \0 > 255
	dc.b  <bb_push16,>\0,<\0
	else
	dc.b <bb_push8,\0
	endif
	ENDM

	MACRO BB_MUL
	dc.b <bb_mul
	ENDM

	MACRO BB_BOOL
	dc.b <bb_bool
	ENDM
 IFD HAVE_DUB
	MACRO BB_DUB
	dc.b <bb_dub
	ENDM
 ENDIF
 IFD HAVE_SWAP
	MACRO BB_SWAP
	dc.b <bb_swap
	ENDM
 ENDIF
	MACRO DONE
	dc.b <bb_again
	ENDM

;;; - Skip commands
Start::
	jmp	init

BITABS_OPCODE	EQU $2c
ORA_OPCODE	EQU $1D		;15
AND_OPCODE	EQU $3D
EOR_OPCODE	EQU $5D
ADC_OPCODE	EQU $7D
SBC_OPCODE	EQU $fD
ROL_OPCODE	EQU $36
ROR_OPCODE	EQU $76
STA_OPCODE	equ $9d

bb_t::
	lda	t+1
	pha
	lda	t
	bra	_pha_ret

bb_shl::
	ply
	pla

	pla
	tsx
.1
	asl
	rol	$101,x
	dey
	bne	.1
	bra	_pha_ret

bb_shr::
	ply
	pla

	pla
	tsx
.1
	lsr	$101,x
	ror
	dey
	bne	.1
	bra	_pha_ret

bb_logic::
bb_sub
	sec			; must be first, C == 0 on preset
	lda	#SBC_OPCODE
	dc.b	BITABS_OPCODE
bb_add
	lda	#ADC_OPCODE
	dc.b	BITABS_OPCODE
bb_eor
	lda	#EOR_OPCODE
	dc.b	BITABS_OPCODE
bb_or
	lda	#ORA_OPCODE
	dc.b	BITABS_OPCODE
bb_and
	lda	#AND_OPCODE
	sta	.smc
	ldy	#2-1
.1
	tsx
	lda $103,x		; get previous
.smc	and $101,x		; combine with current
	sta $103,x		; store to previous
	pla			; pop current
	dey
	bpl	.1
_ret:
	jmp	main

bb_push8:
	phy
.p8
	lda	(pc)
	inc	pc
_pha_ret
	pha
	bra	_ret

bb_push16:
	lda	(pc)
	inc	pc
	pha
	bra	.p8

bb_mul::
.1	pla
	sta	MATHE_C,y	; Note: MATHE_E+1 must be written last!
	iny
	cpy	#4
	bne	.1
	WAITSUZY
	lda	MATHE_A+1
	pha
	lda	MATHE_A
	bra	_pha_ret

	;; a = (a != 0)
bb_bool::
	pla
	sta	tmp
	pla
	ldx	#0
	phx
	ora	tmp
	beq	.1
	inx
.1
	phx
	bra	_ret

 IFD HAVE_DUB
	;; double stack top
bb_dub:
	plx
	pla
	phx
	pha
	phx
	bra	_pha_ret
 ENDIF
 IFD HAVE_SWAP
	;; swap stack top
bb_swap:
	ldy	#3
.1
	pla
	sta	tmp,y
	dey
	bpl	.1
.2
	lda	tmp,y
	pha
	iny
	cpy	#4
	bne	.2
	bra	_ret
 ENDIF
;;; ======================================================================
	;; Program code must be within a single page (too).
program:
	include "song.lb"
;;; ======================================================================
	DONE
program_end:

;;; ----------------------------------------
init::
	lda	#$c
	sta	$fff9		; map vectors to RAM

 IFD HAVE_8000Hz
	;; set frame rate to 77Hz => HBL 8000Hz
	lda	#125
	sta	$fd00
	lda	#$20
	sta	$fd93
 ENDIF
	;; init sound system
	stz	$fd50
;; init sound system
//->	MOVEI	baseClock,$fffe
	sty	$ffff		; Y = 2 from LynxROM
	lda	#<baseClock
	sta	$fffe
bb_again::
	pla			; get result
	sta	$fdb0		; set color
	sec
	sbc	#128		; Lynx uses signed output
	sta	$fd22
	sta	$fd22+8		; louder: Output on a second channel

	;; Cleaner: Latch t if formula runs too long
	;; for the 249B intro, we just hope for the best ...
//->	sei
//->	lda	t
//->	sta	t_latch
//->	lda	t+1
//->	sta	t_latch+1
	cli

	lda	#$80
	tsb	$fd01		; enable HBL interrupt
	tax
	txs			; and init SP
//->	MOVEI	program,pc	; PC+1 is set to $2 by LynxROM
	lda	#<program
	sta	pc
main::
	lda	(pc)
	inc	pc
	sta	.jmp+1		; SMC

	clc			; preset for ADC
	ldy	#0
.jmp
	jmp	$200

;;; HBL
baseClock::
	pha
	lda	#1
	sta	$fd80		; ACK irq

	inc	t
	bne	.1
	inc	t+1
.1
	pla
	rti

	echo "Program:%xprogram"
;;;------------------------------
End:
 IFND LNX
	;; Lynx rom clears to zero after boot loader!
	dc.b 0
 ENDIF

size	set End-Start
free	set 249-size
psize	set program_end-program
	IF free > 1
	REPT	free
	dc.b	$42
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree  Program:%xprogram %dpsize"
