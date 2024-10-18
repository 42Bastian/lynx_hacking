START_X		equ 3
START_Y		equ 5
START_ANGLE	equ 92

DEBUG	set 1			; if defined BLL loader is included
;>BRKuser	  set 1		; define if you want to use debugger

Baudrate	set 62500

	include <includes/hardware.inc>
	include <macros/mikey.mac>
	include <macros/suzy.mac>

	;; fixed address stuff

screen1		equ $FFF0-SCREEN.LEN
screen0		equ screen1-SCREEN.LEN

START_MEM	EQU screen0-SCREEN.LEN

	include <macros/help.mac>
	include <macros/if_while.mac>
	include <macros/font.mac>
	include <macros/debug.mac>
	include <macros/irq.mac>

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
dirXhalf	ds 2
dirYhalf	ds 2

stepX		ds 2
posX		ds 2
dirX::		ds 2
planeX::	ds 2
rayDirX::	ds 2
sideDistX::	ds 2
deltaDistX	ds 2
rayDirX0:	ds 3


stepY		ds 2
posY		ds 2
dirY		ds 2
planeY		ds 2
rayDirY		ds 2
sideDistY	ds 2
deltaDistY	ds 2
rayDirY0	ds 3

rayDirXdelta	ds 3
rayDirYdelta	ds 3

perpWallDist	ds 2

side		ds 1

world_ptr	ds 2
angle		ds 1
wallX		ds 1
lhit		ds 1
tmp0		ds 2
tmp1		ds 2
 END_ZP

	echo "stepX     :%HstepX"
	echo "posX      :%HposX"
	echo "dirX      :%HdirX"
	echo "planeX    :%HplaneX"
	echo "rayDirX   :%HrayDirX"
	echo "sideDistX :%HsideDistX"
	echo "deltaDistX:%HdeltaDistX"
	echo "rayDirX0  :%HrayDirX0"

; main-memory variables
;

 BEGIN_MEM
irq_vectors	ds 16

 END_MEM
;
; code
;

	run $200

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
	jsr InitComLynx

	INITFONT SMALLFNT,2,15
	SET_MINMAX 0,0,160,102

	SETIRQ 0,HBL
	SETIRQ 2,VBL

	cli			; don`t forget this !!!!

	SCRBASE screen0,screen1

	SETRGB pal		; set color

	lda	#START_X
	sta	posX+1
	lda	#START_Y
	sta	posY+1
	lda	#START_ANGLE
	sta	angle

.newDirLoop:
	jsr	getDirPlane
;
; main-loop
;
.loop
//->	stz	$fda0
	SWITCHBUF
//->	dec 	$fda0

	jsr	cls

	clc
	lda	dirX
	adc	planeX
	tax
	lda	dirX+1
	adc	planeX+1
	cmp	#$80
	ror
	sta	rayDirX0+2
	txa
	ror
	sta	rayDirX0+1
	stz	rayDirX0

	clc
	lda	dirY
	adc	planeY
	tax
	lda	dirY+1
	adc	planeY+1
	cmp	#$80
	ror
	sta	rayDirY0+2
	txa
	ror
	sta	rayDirY0+1
	stz	rayDirY0

	ldx	#planeX
	jsr	mulX_410
	sta	rayDirXdelta
	sty	rayDirXdelta+1
	stx	rayDirXdelta+2

	ldx	#planeY
	jsr	mulX_410
	sta	rayDirYdelta
	sty	rayDirYdelta+1
	stx	rayDirYdelta+2

//->	brk	#1
	stz	lhit
	ldx	#159
.xloop
	stx	line_x
	phx

;;; //calculate ray position and direction
	sec
	lda	rayDirX0
	sbc	rayDirXdelta
	sta	rayDirX0
	lda	rayDirX0+1
	sta	rayDirX
	sbc	rayDirXdelta+1
	sta	rayDirX0+1
	lda	rayDirX0+2
	sta	rayDirX+1
	sbc	rayDirXdelta+2
	sta	rayDirX0+2

	sec
	lda	rayDirY0
	sbc	rayDirYdelta
	sta	rayDirY0
	lda	rayDirY0+1
	sta	rayDirY
	sbc	rayDirYdelta+1
	sta	rayDirY0+1
	lda	rayDirY0+2
	sta	rayDirY+1
	sbc	rayDirYdelta+2
	sta	rayDirY0+2

//->    int stepX = 0;
//->    int deltaDistX = fp*fp;
//->    int sideDistX =  sideDistX0;

	stz	stepX
	stz	stepX+1
	stz	stepY
	stz	stepY+1
	lda	#$ff
	sta	deltaDistX
	sta	deltaDistX+1
	sta	deltaDistY
	sta	deltaDistY+1
	lda	posX
	sta	sideDistX
	stz	sideDistX+1
	lda	posY
	sta	sideDistY
	stz	sideDistY+1

//->    if ( rayDirX/2 != 0 ) {
//->      deltaDistX = delta(abs(rayDirX/2));
//->      //deltaDistX = abs(fp*fp / rayDirX);
//->
//->      if (rayDirX < 0) {
//->        stepX = -1;
//->        sideDistX = (sideDistX/n) * deltaDistX/(fp/n);
//->      } else {
//->        stepX = 1;
//->        sideDistX = (fp - sideDistX)/n * deltaDistX/(fp/n);
//->      }
//->    }

	lda	rayDirX
	tax
	ora	rayDirX+1
	beq	.rayDirXZero

	ldy	#1
	bbr7	rayDirX+1,.rayDirPlus
	txa
	eor	#$ff
	inc
	tax
	ldy	#$ff
	sty	stepX+1
.rayDirPlus
	lda	deltatab_lo,x
	sta	deltaDistX
	sta	MATHE_C
	lda	deltatab_hi,x
	sta	deltaDistX+1
	sta	MATHE_C+1
	lda	sideDistX+1
	ldx	sideDistX
	cpy	#0
	bmi	.rayDirMinus
	clc
	txa
	eor	#$ff
	adc	#1
	tax
	lda	sideDistX+1
	eor	#$ff
	adc	#1
.rayDirMinus:
	stx	MATHE_E
	sta	MATHE_E+1
	NOP8
	lda	MATHE_A+1
	sta	sideDistX
	lda	MATHE_A+2
	sta	sideDistX+1
	sty	stepX
.rayDirXZero:

;;->    if ( rayDirY/2!= 0 ) {
;;->      deltaDistY = delta(abs(rayDirY/2));
;;->      //deltaDistY = abs(fp*fp / rayDirY);
;;->
;;->      if (rayDirY > 0) {
;;->        stepY = -1;
;;->        sideDistY = (sideDistY/n) * deltaDistY/(fp/n);
;;->      } else {
;;->        stepY = 1;
;;->        sideDistY = (fp - sideDistY)/n * deltaDistY/(fp/n);
;;->      }
;;->    }

	lda	rayDirY
	tax
	ora	rayDirY+1
	beq	.rayDirYZero

	ldy	#-16
	dec	stepY+1
	bbr7	rayDirY+1,.rayDirYPlus
	txa
	eor	#$ff
	inc
	tax
	ldy	#16
	stz	stepY+1
.rayDirYPlus
	lda	deltatab_lo,x
	sta	deltaDistY
	sta	MATHE_C
	lda	deltatab_hi,x
	sta	deltaDistY+1
	sta	MATHE_C+1

	lda	sideDistY+1
	ldx	sideDistY
	cpy	#0
	bmi	.rayDirYPlus2

	clc
	txa
	eor	#$ff
	adc	#1
	tax
	lda	sideDistY+1
	eor	#$ff
	adc	#1
.rayDirYPlus2:
	stx	MATHE_E
	sta	MATHE_E+1
	NOP8
	lda	MATHE_A+1
	sta	sideDistY
	lda	MATHE_A+2
	sta	sideDistY+1
	sty	stepY
.rayDirYZero:

	lda	posY+1
	ldy	#16
	jsr	mulAY
	clc
	adc	#<world
	sta	world_ptr
	lda	MATHE_A+2
	adc	#>world
	sta	world_ptr+1

	clc
	lda	posX+1
	adc	world_ptr
	sta	world_ptr
	_IFCS
	  inc	world_ptr+1
	_ENDIF

;;->    while (hit == 0 ) {
;;->      //jump to next map square, either in x-direction, or in y-direction
;;->      if (sideDistX < sideDistY) {
;;->        sideDistX += deltaDistX;
;;->        mapX += stepX;
;;->        side = 0;
;;->      } else {
;;->        sideDistY += deltaDistY;
;;->        mapY += stepY;
;;->        side = 1;
;;->      }
;;->      //Check if ray has hit a wall
;;->      hit = map(mapX, mapY);
;;->    }

.wallloop:
	stz	side
	CMPW	sideDistY,sideDistX
	_IFCC
	  lda	deltaDistX
	  adc	sideDistX
	  sta	sideDistX
	  lda	deltaDistX+1
	  adc	sideDistX+1
	  sta	sideDistX+1

	  clc
	  lda stepX
	  adc world_ptr
	  sta world_ptr
	  lda stepX+1
	  adc world_ptr+1
	  sta world_ptr+1
	_ELSE
	  inc side
	  ADDW	deltaDistY,sideDistY
	  clc
	  lda stepY
	  adc world_ptr
	  sta world_ptr
	  lda stepY+1
	  adc world_ptr+1
	  sta world_ptr+1
	_ENDIF
	lda	(world_ptr)
	beq	.wallloop

	bbr0	side,.left
	clc
	adc	#8
.left
	sta	line_color

//->    int perpWallDist;
//->    if (side == 0) perpWallDist = (sideDistX - deltaDistX);
//->    else           perpWallDist = (sideDistY - deltaDistY);

	_IFEQ side
	sec
	lda	sideDistX
	sbc	deltaDistX
//->	sta	perpWallDist
	sta	MATHE_B
	lda	sideDistX+1
	sbc	deltaDistX+1
//->	sta	perpWallDist+1
	sta	MATHE_B+1
	_ELSE
	sec
	lda	sideDistY
	sbc	deltaDistY
//->	sta	perpWallDist
	sta	MATHE_B
	lda	sideDistY+1
	sbc	deltaDistY+1
//->	sta	perpWallDist+1
	sta	MATHE_B+1
	_ENDIF

	lda	#102
	stz	MATHE_A
	sta	MATHE_A+1
	stz	MATHE_A+2
	stz	MATHE_A+3
	WAITSUZY
	lda	MATHE_D
	sta	line_ysize+1
	eor	#$ff
	sec
	adc	#102
	_IFCC
	  lda	#0
	_ENDIF
	lsr
	sta	line_y
;;->line_height = (_height*fp / perpWallDist);
	LDAY	lineSCB
	jsr	DrawSprite
//->	cmp	#3
//->	bne	.xx
//->	brk 	#1
//->.xx
	plx
	dex
	cpx	#$ff
	beq	.done
	jmp	.xloop
.done

.0
	READKEY		; see MIKEY.MAC
	lda 	Button
	beq	.1
.cont
	jmp	.loop
.1
	lda Cursor
	beq .cont
	bit #$30	; left|right
	_IFNE
	  clc
	  bit #JOY_RIGHT
	  _IFNE
	  lda angle
	   adc #4
          _ELSE
	  lda angle
	   sbc #3
	  _ENDIF
	  sta angle
	_ELSE
	  bit #JOY_UP
	  _IFNE
	    clc
	    lda posX
	    adc dirXhalf
	    sta posX
	    lda posX+1
	    adc dirXhalf+1
	    sta posX+1
	    sec
	    lda posY
	    sbc dirYhalf
	    sta posY
	    lda posY+1
	    sbc dirYhalf+1
	    sta posY+1
	  _ELSE
	    sec
	    lda posX
	    sbc dirXhalf
	    sta posX
	    lda posX+1
	    sbc dirXhalf+1
	    sta posX+1
	    clc
	    lda posY
	    adc dirYhalf
	    sta posY
	    lda posY+1
	    adc dirYhalf+1
	    sta posY+1
	  _ENDIF
	_ENDIF

	jmp .newDirLoop

;;; ----------------------------------------
;;  dirX = -co(angle);
;;  dirY = si(angle);
;;  planeX = 6*si(angle)/8;
;;  planeY = 6*co(angle)/8;

getDirPlane::
	ldy	#0
	ldx	angle
	lda	sintab_lo+64,x
	sta	tmp0
	clc
	eor	#$ff
	adc	#1
	sta	dirX
	lda	sintab_hi+64,x
	sta	tmp0+1
	eor	#$ff
	adc	#0
	sta	dirX+1

	lda	dirX+1
	cmp	#$80
	ror
	sta	dirXhalf+1
	lda	dirX
	ror
	sta	dirXhalf

	lda	sintab_lo,x
	sta	dirY
	ldy	sintab_hi,x
	sty	dirY+1
	jsr	mul6div8

	sta	planeX+1
	sty	planeX

	lda	tmp0
	ldy	tmp0+1

	jsr	mul6div8
	sta	planeY+1
	sty	planeY

	lda	dirY+1
	cmp	#$80
	ror
	sta	dirYhalf+1
	lda	dirY
	ror
	sta	dirYhalf

	rts

mul6div8::
	sta	tmp1
	sty	tmp1+1
	asl	tmp1
	rol	tmp1+1
	clc
	adc	tmp1
	sta	tmp1
	tya
	adc	tmp1+1
	asl	tmp1
	rol

	cmp	#$80
	ror
	ror	tmp1

	cmp	#$80
	ror
	ror	tmp1

	cmp	#$80
	ror
	ror	tmp1

	ldy	tmp1
	rts

mulX_410::
	lda	0,x
	sta	MATHE_C
	lda	1,x
	sta	MATHE_C+1
	lda	#<410
	sta	MATHE_E
	lda	#>410
	sta	MATHE_E+1
	NOP8
	lda	MATHE_A+1
	ldy	MATHE_A+2
	ldx	MATHE_A+3
	rts

mulAY::
	stz	MATHE_E
	sta	MATHE_C		; A = C * E
	sty	MATHE_E+1
	NOP8
	lda	MATHE_A+1
	rts

posTxt:
	dc.b "Position :",0

lineSCB:
	dc.b SPRCTL0_16_COL|SPRCTL0_NORMAL
	dc.b SPRCTL1_DEPTH_SIZE_RELOAD|SPRCTL1_LITERAL
	dc.b 0
	dc.w 0,line_data
line_x	dc.w 0
line_y	dc.w 51
	dc.w $100
line_ysize
	dc.w $800
line_color:
	dc.b $0
line_data:
	dc.b 2,$10,0

HBL::
	dec	hbl_count
	_IFMI
	  clc
	  lda	$fdb0
	  adc	#$10
	  _IFCS
	    lda	#127
	  _ELSE
	   sta	$fdb0
	   lda	#1
	_ENDIF
	sta	hbl_count
	_ENDIF
	END_IRQ

VBL::
	lda	#2
	sta	hbl_count
	stz	$fdb0
	END_IRQ

;
; clear screen
;
cls
	LDAY clsSCB
	jmp DrawSprite

clsSCB
	dc.b $c0,$90,$00
	dc.w cls2SCB,cls_data
	dc.w 0,0
	dc.w 160*$100,51*$100
	dc.b $00

cls2SCB
	dc.b $c0,$90,$00
	dc.w 0,cls_data
	dc.w 0,51
	dc.w 160*$100,51*$100
	dc.b $88

cls_data
	dc.b 2,$10,0


	include <includes/irq.inc>
	include <includes/debug.inc>
	include <includes/serial.inc>

	include <includes/hexdez.inc>
	include <includes/font.inc>
	include <includes/draw_spr.inc>
	include <includes/font2.hlp>

pal
	STANDARD_PAL

	include "sintab.inc"
	include "deltatab.inc"
	include "world.inc"