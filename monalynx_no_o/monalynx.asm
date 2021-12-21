***************
* Lynx port of "MONA"
* Main routine
****************

	include <includes/hardware.inc>
	include <macros/help.mac>

 IFND LNX
 error "No more .o"
 ENDIF

;;; ROM sets this address
screen0	 equ $2000

	include "monalynx.var"

	run $232		; first byte after decrypted header

main	equ $224		; check with monaload.equ !

Start::
	lda	RCART0
	sta	seed+1
	sta	plot_y
	phy
;;;------------------------------
.loop0
	smb5	path_length	; path_length = 32 (zp 0 == 0 after ROM !)
.loop
	asl	seed
	rol	seed+1
	rol	seed+2
	rol	seed+3
	bcc	.noxor

	ldx	#3
.l1
	lda	mask,x
	eor	seed,x
	sta	seed,x
	dex
	bpl	.l1
	and	#$82
	sta	dir
.noxor:
	;; next pixel position
	lda	dir
	asl
	tax
	bcs	.minus
	inc	plot_y,x
	dc.b	$AD		; Opcode: LDA nn => skip "dec plot_x,x"
.minus
	dec	plot_y,x

	rmb7	plot_x		; == and #$7f
	rmb7	plot_y

	;; calculate byte position
	lda	plot_y
	cmp	#96		; brushes are calculated for 128x96!
	bcs	.skip

	sta	MATHE_C
	lda	#80
	sta	MATHE_E+1
.ws
	bit	SPRSYS
	bmi	.ws

	lda	plot_x
	lsr			; x => byte position
	clc
	adc	MATHE_A+1
	sta	ptr
	lda	MATHE_A+2
	adc	#$20
	sta	ptr+1		; ptr => byte

	;; set pixel
	ldx	#$f0
	lda	plot_color
	and	#3		; only 0..3
	bbs0	plot_x,.1	; odd pixel ? (== low nibble)
	asl
	asl
	asl
	asl
	ldx	#$f
.1
	sta	tmp		; save shifted color
	txa			; get mask
	and	(ptr)		; preserve other pixel
	ora	tmp		; get color
	sta	(ptr)		; store both
.skip
	dec	path_length
	bne	.loop
	dey
	bpl	.loop0
	ply
	dey
.done
	bmi	.done
	jmp	main

mask:	dc.b $b7,$1d,$c1,$04
	dc.b $7e		; => seed+3 (last byte loaded)

	;; table will not be loaded by monaload!
brush::
	dc.w 0x030A, 0x37BE, 0x2F9B, 0x072B, 0x0E3C, 0xF59B, 0x8A91, 0x1B0B
	dc.w 0x0EBD, 0x9378, 0xB83E, 0xB05A, 0x70B5, 0x0280, 0xD0B1, 0x9CD2
	dc.w 0x2093, 0x209C, 0x3D11, 0x26D6, 0xDF19, 0x97F5, 0x90A3, 0xA347
	dc.w 0x8AF7, 0x0859, 0x29AD, 0xA32C, 0x7DFC, 0x0D7D, 0xD57A, 0x3051
	dc.w 0xD431, 0x542B, 0xB242, 0xB114, 0x8A96, 0x2914, 0xB0F1, 0x532C
	dc.w 0x0413, 0x0A09, 0x3EBB, 0xE916, 0x1877, 0xB8E2, 0xAC72, 0x80C7
	dc.w 0x5240, 0x8D3C, 0x3EAF, 0xAD63, 0x1E14, 0xB23D, 0x238F, 0xC07B
	dc.w 0xAF9D, 0x312E, 0x96CE, 0x25A7, 0x9E37, 0x2C44, 0x2BB9, 0x2139

End:
size	set End - $200
oversize set size - 256

	echo "Size:%dsize Oversize:%doversize"
