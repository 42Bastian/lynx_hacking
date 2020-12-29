***************
* Minimal Suzy setup for sprites (no tricks).
* 20 byte free.
****************

	include <includes/hardware.inc>

Baudrate EQU 62500

;;; ROM sets this address
screen0	 equ $2000


 IFD LNX
	run	$200
 ELSE
	;; BLL loader is at $200, so move up
	run	$400
 ENDIF

 IFND LNX
	;; Setup needed if loaded via BLL/Handy
	lda	#8
	sta	$fff9
	cli
	lda	#$20
	stz	$fd94
	sta	$fd95
	stz 	$fd50
	ldy	#2
 ENDIF

Start::
	lda	#$f
	sta	$fdb3
	stz	$fda0
	ldx	#9-1
.mloop
	  ldy	SUZY_addr,x
	  lda	SUZY_data,x
          sta	$fc00,y
          dex
        bpl .mloop

	lda	#<plot_SCB	; Could be moved into SUZY_addr/data!
	sta	SCBNEXT
	lda	#>plot_SCB
	sta	SCBNEXT+1
	lda	#1
	STA	SPRGO		; start drawing

	STZ	SDONEACK
	STZ	CPUSLEEP

	ldx #LoaderLen-1	; put Loader in the right place
.loop	  lda _Loader,x
	  sta Loader,x
	  dex
	bpl .loop

main::
	lda #%11101
	sta $fd8c
	lda #%00011000	 ; enable count,enable reload
	sta $fd11
	lda #125000/Baudrate-1
	sta $fd10

wait:
	jsr	read_byte
	cmp	#0x81
	bne	wait
	jsr	read_byte
	cmp	#'P'
	bne	wait
	jmp	Loader

load_len	equ $0
load_ptr	equ $2
load_ptr2	equ $4

_Loader	set *	; save current PC

	RUN $100-55	; place Loader in ZP

Loader::
	ldy #4
.loop0	  jsr read_byte
	  sta load_len-1,y
	  dey
	bne .loop0	; get destination and length
	tax	; lowbyte of length

	lda load_ptr
	sta load_ptr2
	lda load_ptr+1
	sta load_ptr2+1

.loop1	inx
	bne .1
	inc load_len+1
	bne .1
	jmp (load_ptr)

.1	jsr read_byte
	sta (load_ptr2),y
	sta $fda0
	iny
	bne .loop1
	inc load_ptr2+1
	bra .loop1


read_byte
	bit $fd8c
	bvc read_byte
	lda $fd8d
	rts

LoaderE	equ *

LoaderLen	equ LoaderE-Loader

	echo "%DLoaderLen"
	RUN _Loader+LoaderLen
;;;------------------------------
	;; Writing low-byte in SUZY space clears highbyte!
SUZY_addr
	db $09,$08,$04,$06,$28,$2a,$83,$92,$90
SUZY_data
	db $20,$00,$00,$00,$7f,$7f,$f3,$00,$01
plot_SCB:
	dc.b SPRCTL0_BACKGROUND_NON_COLLIDABLE		;0
	dc.b SPRCTL1_LITERAL| SPRCTL1_DEPTH_SIZE_RELOAD	;1
	dc.b 0
	dc.w next
	dc.w cls_data
	dc.w 0,0
	dc.w 160*$100,102*$100
	dc.b $00
cls_data:
	dc.b 2,00,0

next:
	db $01						;0
	dc.b SPRCTL1_LITERAL| SPRCTL1_DEPTH_SIZE_RELOAD ;1
	dc.b 0						;2
	dc.w 0						;3
	dc.w plot_data					;5
plot_x	dc.w 80-21					;7
plot_y	dc.w 51-3					;9
        dc.w $100					;11
        dc.w $200					;13
plot_color:						;15
	db	3

plot_data:
	;; "OUTLINE"
	;; centered
	ibytes "new_bll.spr"
 IFND LNX
	;; Lynx rom clears to zero after boot loader!
	dc.b 0
 ENDIF
End:
size	set End-Start
free 	set 247-size

	IF free > 0
	REPT	free
	dc.b	0
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree"
