***************
* Mini COMLynx Loader (not size optimized)
* 17 byte free.
****************

	include <includes/hardware.inc>

Baudrate EQU 62500

;;; ROM sets this address
screen0	 equ $2000

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
 ENDIF

Start::
	ldx	#12-1
.sloop
	  ldy	SUZY_addr,x
	  lda	SUZY_data,x
          sta	$fc00,y
          dex
        bpl .sloop

	ldx	#7-1
.mloop
	  ldy	MIKEY_addr,x
	  lda	MIKEY_data,x
	  sta   $fd00,y
	  dex
	bpl	.mloop

	ldx #LoaderLen-1	; put Loader in the right place
.loop	  lda _Loader,x
	  sta Loader,x
	  dex
	bpl .loop

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
load_len2	equ $4
load_ptr2	equ $6

_Loader	set *	; save current PC

	RUN $100-50	; place Loader in ZP

Loader::
	ldy #4
.loop0	  jsr read_byte
	  sta load_len-1,y
	  sta load_len2-1,y
	  dey
	bne .loop0	; get destination and length
	tax	; lowbyte of length

.loop1	inx
	bne .1
	inc load_len+1
	bne .1
	jmp (load_ptr)

.1	jsr read_byte
	sta (load_ptr2),y
	sta $fdb0
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
_SDONEACK EQU SDONEACK-$fd00
_CPUSLEEP EQU CPUSLEEP-$fd00
MIKEY_addr
	dc.b	$10,$11,$8c,_CPUSLEEP,_SDONEACK,$b3,$a0

MIKEY_data
	dc.b	125000/Baudrate-1,%11000,%11101,0,0,$0f,0

_SCBNEXT EQU SCBNEXT-$fc00
_SPRGO   EQU SPRGO-$fc00
SUZY_addr
	db _SPRGO,_SCBNEXT+1,_SCBNEXT,$09,$08,$04,$06,$28,$2a,$83,$92,$90
SUZY_data
	db 1,>plot_SCB,<plot_SCB,$20,$00,$00,$00,$7f,$7f,$f3,$00

plot_SCB:
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
	;; "NEW_BLL"
	ibytes "new_bll.spr"

 IFND LNX
	;; Lynx rom clears to zero after boot loader!
	dc.b 0
 ENDIF
End:
size	set End-Start
free	set 199-size

	IF free > 0
	REPT	free
	dc.b	$42
	ENDR
	ENDIF

	echo "Size:%dsize  Free:%dfree"
