Baudrate	set 62500

firstV2LSector	equ 1

	include <includes/hardware.inc>
	include <macros/mikey.mac>
	include <macros/suzy.mac>

	;; fixed address stuff

screen1		equ $FFF0-SCREEN.LEN
screen0		equ screen1-SCREEN.LEN

START_MEM	EQU screen0-1024


BlockSize	equ 2048

	include <macros/help.mac>
	include <macros/if_while.mac>
	include <macros/font.mac>
	include <macros/debug.mac>
	include <macros/irq.mac>
	include <macros/lnx_header.mac>
;
; essential variables
;
	include <vardefs/debug.var>
	include <vardefs/irq.var>
	include <vardefs/serial.var>

	include <vardefs/mikey.var>
	include <vardefs/suzy.var>
	include <vardefs/font.var>

;
; local MACROs
;

;
; zero-page
;
 BEGIN_ZP
hbl_count	ds 1
tmp0		ds 2
tmp1		ds 2
vbl_count	ds 2
CurrBlock	ds 1
BlockByte	ds 2
command		ds 1
 END_ZP

 BEGIN_MEM
irq_vectors	ds 16

 END_MEM
;
; code
;

 IFD LNX
	run	0
	LNX_HEADER BlockSize,0,"VGMplay","42Bastian",0,0

	run 0
	ibytes	<uloader/ml512.enc>
size_of_loader:

	run $1ff
	dc.b 1+((end-Start)>>8)
 ELSE
	run $200
 ENDIF

Start::
	START_UP
	CLEAR_MEM
	CLEAR_ZP +STACK

	INITMIKEY
	INITSUZY

	lda	_SPRSYS
	ora	#SIGNED_MATH
	sta	_SPRSYS
	sta	SPRSYS

	INITIRQ irq_vectors
//->	jsr InitComLynx

//->	INITFONT LITTLEFNT,0,15
//->	SET_MINMAX 0,0,160,102

//->	SETIRQ 0,HBL
	SETIRQ 2,VBL
	SETIRQ 7,VGM

	cli			; don`t forget this !!!!

	SCRBASE screen0

	SETRGB pal		; set color

    lda #$ff
    sta MPAN
    stz MSTEREO
    stz VOLUME_A
    stz VOLUME_B
    stz VOLUME_C
    stz VOLUME_D

	lda	#1
	jsr	VGM_SelectBlock
	jsr	streamHandler

; main-loop
;
.loop
	bra	.loop

VBL::
//->	stz	$fda0
	END_IRQ

VGM::
	phy
	jsr	streamHandler
	ply
	END_IRQ

clsSCB:
	dc.b SPRCTL0_16_COL,SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD,$00
	dc.w 0,cls_data
	dc.w 0,0
	dc.w 160*$100,102*$100
	dc.b $00

cls_data
	dc.b 2,$10,0

	include "vgmplay.inc"

;;; ========================================
;;; BLL includes

	include <includes/irq.inc>
	include <includes/debug.inc>
	include <includes/serial.inc>

//->	include <includes/hexdez.inc>
//->	include <includes/font.inc>
	include <includes/draw_spr.inc>
pal
	STANDARD_PAL
	;; should be last!
//->	include <includes/font2.hlp>
end::
size	equ end-Start+1

 IFD LNX

	;; align on $2000 on the cart not RAM !
spare	equ 2048-size-size_of_loader

	if spare < 0
	echo "Code to large"
	else
	REPT spare
	dc.b	$FF
	ENDR
	endif

	ibytes "x.v2l"

 ENDIF
