START_X		equ $300
START_Y		equ $700
START_ANGLE	equ 180

 IFND HALF_REZ
HALF_REZ	equ 0
 ENDIF

Baudrate	set 62500

	include <includes/hardware.inc>
	include <macros/mikey.mac>
	include <macros/suzy.mac>

	;; fixed address stuff

screen1		equ $FFF0-SCREEN.LEN
screen0		equ screen1-SCREEN.LEN

START_MEM	EQU screen0-1024



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
hit		ds 1
wallside	ds 1

stepX		ds 1
posX		ds 2
dirX::		ds 2
planeX::	ds 2
rayDirX::	ds 2
sideDistX::	ds 2
deltaDistX	ds 2
dirXhalf	ds 2

stepY		ds 1
posY		ds 2
dirY		ds 2
planeY		ds 2
rayDirY		ds 2
sideDistY	ds 2
deltaDistY	ds 2
dirYhalf	ds 2

rayDirX0:	ds 3
rayDirXdelta	ds 3
rayDirY0	ds 3
rayDirYdelta	ds 3

perpWallDist	ds 2
side		ds 1
base_color	ds 1
world_ptr	ds 2
angle		ds 1
wallX		ds 1
floor		ds 1
lhit		ds 1
textureLo	ds 2
textureHi	ds 2
tmp0		ds 2
tmp1		ds 2
vbl_count	ds 2
step		ds 1
 END_ZP
	echo "hit       :%Hhit"

	echo "stepX     :%HstepX"
	echo "posX      :%HposX"
	echo "dirX      :%HdirX"
	echo "planeX    :%HplaneX"
	echo "rayDirX   :%HrayDirX"
	echo "sideDistX :%HsideDistX"
	echo "deltaDistX:%HdeltaDistX"
	echo "dirXhalf  :%H dirXhalf"
	echo "--"
	echo "rayDirX0  :%H rayDirX0"
	echo "rayDirXd. :%H rayDirXdelta"
	echo "rayDirY0  :%H rayDirY0"


	echo "perpWallD.:%H perpWallDist"
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
//->	jsr InitComLynx

	INITFONT LITTLEFNT,0,15
	SET_MINMAX 0,0,160,102

	SETIRQ 0,HBL
	SETIRQ 2,VBL

	cli			; don`t forget this !!!!

	SCRBASE screen0,screen1

	SETRGB pal		; set color

	MOVEI 	START_X,posX
	MOVEI 	START_Y,posY
	lda	#START_ANGLE
	sta	angle


	stz	step
.newDirLoop:
	jsr	getDirPlane

;
; main-loop
;
.loop
//->	stz	$fda0
	SWITCHBUF
	stz	vbl_count
//->	dec 	$fda0

	LDAY skyFloorSCB
	jsr DrawSprite

//->	lda	step
//->	_IFNE
//->	  dec	step
//->	_ENDIF
//->	sta	VOFF

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
	jsr	mulX_410_b
	sta	rayDirYdelta
	sty	rayDirYdelta+1
	stx	rayDirYdelta+2

 IF HALF_REZ = 1
	lda	#79
 ELSE
	lda	#159
 ENDIF
	sta	lhit		; preset last texture
.xloop
	pha
 IF HALF_REZ = 1
	asl
 ENDIF
	sta	line_x

	lda	#$01
	sta	line_color

	stz	stepX
	stz	stepY
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

;;; //calculate ray position and direction
	sec
	lda	rayDirX0
	sbc	rayDirXdelta
	sta	rayDirX0
	lda	rayDirX0+1
	sta	rayDirX
	tax			; save for later
	sta	tmp0
	sbc	rayDirXdelta+1
	sta	rayDirX0+1
	lda	rayDirX0+2
	sta	rayDirX+1
	tsb	tmp0		; zero check
	sbc	rayDirXdelta+2
	sta	rayDirX0+2

;;    if ( rayDirX != 0 ) {
;;      deltaDistX = delta(abs(rayDirX));
;;
;;      if (rayDirX < 0) {
;;        stepX = -1;
;;        sideDistX = sideDistX * deltaDistX/fp;
;;      } else {
;;        stepX = 1;
;;        sideDistX = (fp - sideDistX) * deltaDistX/fp;
;;      }
;;    }

	ldy	#1

	lda	tmp0
	beq	.rayDirXZero

	bbr7	rayDirX+1,.rayDirPlus

	txa
	eor	#$ff
	inc
	tax
	ldy	#$ff
.rayDirPlus
	sty	stepX

	lda	sideDistX

	iny
	beq	.rayDirMinus

	eor	#$ff		; 1s complemnent to avoid carry
.rayDirMinus:
	sta	MATHE_C
	lda	deltatab_lo,x
	sta	deltaDistX
	sta	MATHE_E
	lda	deltatab_hi,x
	sta	deltaDistX+1
	sta	MATHE_E+1
	NOP8
	lda	MATHE_A+1
	sta	sideDistX
	lda	MATHE_A+2
	sta	sideDistX+1
.rayDirXZero:

	sec
	lda	rayDirY0
	sbc	rayDirYdelta
	sta	rayDirY0
	lda	rayDirY0+1
	sta	rayDirY
	tax
	sta	tmp0
	sbc	rayDirYdelta+1
	sta	rayDirY0+1
	lda	rayDirY0+2
	sta	rayDirY+1
	tsb	tmp0
	sbc	rayDirYdelta+2
	sta	rayDirY0+2

;;    if ( rayDirY != 0 ) {
;;      deltaDistY = delta(abs(rayDirY/2));
;;
;;      if (rayDirY > 0) {
;;        stepY = -1;
;;        sideDistY = sideDistY * deltaDistY/fp;
;;      } else {
;;        stepY = 1;
;;        sideDistY = (fp - sideDistY) * deltaDistY/fp;
;;      }
;;    }

	lda	tmp0
	beq	.rayDirYZero

	lda	#16
	ldy	sideDistY

	bbr7	rayDirY+1,.rayDirYPlus

	txa
	eor	#$ff
	inc
	tax

	tya
	eor	#$ff		; 1s complemnent to avoid carry
	tay
	lda	#-16
.rayDirYPlus
	sta	stepY

	sty	MATHE_C

	lda	deltatab_lo,x
	sta	deltaDistY
	sta	MATHE_E
	lda	deltatab_hi,x
	sta	deltaDistY+1
	sta	MATHE_E+1

	NOP8
	lda	MATHE_A+1
	sta	sideDistY
	lda	MATHE_A+2
	sta	sideDistY+1
.rayDirYZero:

	jsr	getWorld_XY

//->	brk	#1
	jsr	scanMap

//->	brk	#1
	cmp	#1
	beq	.edge
	tax
	and	#3
	sta	base_color

;;    if ( side == 0 ) {
;;      wallside = 1; // back
;;      if ( stepX > 0 ) {
;;        wallside = 2; // front
;;      }
;;    } else {
;;      wallside = 3;  // right
;;      if ( stepY < 0 ) {
;;        wallside = 4; // left
;;      }
;;    }

	lda	side
	bne	.left_right
	bit	stepX
	SKIP2
.left_right
	bit	stepY
	bmi	.done_wallside
	inc
.done_wallside
	sta	wallside
	clc
	adc	base_color
	beq	.edge
	sta	line_color
.edge

;; if (side == 0) wallX = (posY - perpWallDist * rayDirY/fp);
;; else           wallX = (posX + perpWallDist * rayDirX/fp);

	lda	perpWallDist
	sta	MATHE_B
	asl
	sta	MATHE_C
	lda	perpWallDist+1
	sta	MATHE_B+1
	rol
	sta	MATHE_C+1

	bbr1	side,.t1

	lda	rayDirX
	sta	MATHE_E
	lda	rayDirX+1
	sta	MATHE_E+1
	NOP8
	clc
	lda	posX
	adc	MATHE_A+1
	bra	.t9
.t1

	lda	rayDirY
	sta	MATHE_E
	lda	rayDirY+1
	sta	MATHE_E+1
	NOP8
	sec
	lda	posY
	sbc	MATHE_A+1
.t9
	stz	MATHE_A
	ldx	#<(102*4)
	stx	MATHE_A+2
	ldx	#>(102*4)
	stx	MATHE_A+3	; start divide (*4 => /64)

	lsr
	lsr
	tay

	lda	hit
	lsr
	lsr
	cmp	lhit
	_IFNE
	  sta	lhit
	  tax
	  lda	textures_lolo,x
	  sta	textureLo
	  lda	textures_lohi,x
	  sta	textureLo+1
	  lda	textures_hilo,x
	  sta	textureHi
	  lda	textures_hihi,x
	  sta	textureHi+1
	_ENDIF

	lda	lhit
	cmp	#3
	beq	.no_mirror
	bbs0	wallside,.no_mirror
	tya
	eor	#63
	tay
.no_mirror

	lda	(textureLo),y
	sta	line_data
	lda	(textureHi),y
	sta	line_data+1

	WAITSUZY		; wait for divide to finish

	lda	MATHE_D+1
	sta	line_ysize
	lda	MATHE_D+2
	sta	line_ysize+1

	LDAY	lineSCB
	jsr	DrawSprite

	pla
	dec
 IF HALF_REZ = 1
	bmi	.done
 ELSE
	cmp	#$ff
	beq	.done
 ENDIF
	jmp	.xloop
.done
	stz	VOFF

	lda	vbl_count
	pha

	SET_XY 1,0
	PRINT info

	SET_XY 8,0
	lda posX+1
	jsr PrintHex
	lda posX
	jsr PrintHex

	SET_XY 35,0
	lda posY+1
	jsr PrintHex
	lda posY
	jsr PrintHex

	SET_XY 62,0
	lda angle
	jsr PrintDecA

	SET_XY 93,0
	pla
	jsr PrintDecA

.0
	READKEY		; see MIKEY.MAC
	lda 	Button
	beq	.1
.cont
	jmp	.loop

info:	dc.b "X:     Y:     A:    VBL:   ",0

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
	    jsr moveForward
	  _ELSE
	    jsr moveBackward
	  _ENDIF
	  _IFEQ step
	  lda	#4
	  sta	step
	  _ENDIF
	_ENDIF

	jmp .newDirLoop

;;; ----------------------------------------
;;    while (hit == 0 ) {
;;      //jump to next map square, either in x-direction, or in y-direction
;;      if (sideDistX < sideDistY) {
;;        perpWallDist = sideDistX;
;;        sideDistX += deltaDistX;
;;        mapX += stepX;
;;        side = 0;
;;      } else {
;;        perpWallDist = sideDistY;
;;        sideDistY += deltaDistY;
;;        mapY += stepY;
;;        side = 1;
;;      }
;;      //Check if ray has hit a wall
;;      hit = map(mapX, mapY);
;;    }

scanMap::
.wallloop:
	ldx	#0
	CMPW	sideDistY,sideDistX
	_IFCC
	  lda	sideDistX
	  sta	perpWallDist
	  adc	deltaDistX
	  sta	sideDistX
	  lda	sideDistX+1
	  sta	perpWallDist+1
	  adc	deltaDistX+1
	  sta	sideDistX+1

	  clc
	  tya
	  adc	stepX
	_ELSE
	  ldx #2

	  clc
	  lda	sideDistY
	  sta	perpWallDist
	  adc	deltaDistY
	  sta	sideDistY
	  lda	sideDistY+1
	  sta	perpWallDist+1
	  adc	deltaDistY+1
	  sta	sideDistY+1

	  sec
	  tya
	  sbc	stepY

	_ENDIF
	tay
	lda	(world_ptr),y
	beq	.wallloop

	stx	side
	sta	hit

	rts
;;; ----------------------------------------
;;; Move dirXhalf step backward
moveBackward::
	sec
	lda	posX
	sta	tmp1
	sbc	dirX
	sta	posX
	lda	posX+1
	sta	tmp1+1
	sbc	dirX+1
	sta	posX+1
	jsr	getWorld_XY
	_IFNE
	  lda	tmp1
	  sta	posX
	  lda	tmp1+1
	  sta	posX+1
	_ELSE
	  SUBWABC dirXhalf,tmp1,posX
	_ENDIF
	clc
	lda	posY
	sta	tmp1
	adc	dirY
	lda	posY+1
	sta	tmp1+1
	adc	dirY+1
	sta	posY+1
	jsr	getWorld_XY
	_IFNE
	  lda	tmp1
	  sta	posY
	  lda	tmp1+1
	  sta	posY+1
	_ELSE
	   ADDWABC dirYhalf,tmp1,posY
	_ENDIF
	rts
;;; ----------------------------------------
;;; Move dirXhalf step forward
moveForward::
	clc
	lda 	posX
	sta	tmp1
	adc	dirX
	sta	posX
	lda	posX+1
	sta	tmp1+1
	adc	dirX+1
	sta	posX+1
	jsr	getWorld_XY
	_IFNE
	   lda	tmp1
	   sta	posX
	   lda	tmp1+1
	   sta	posX+1
	_ELSE
	  ADDWABC tmp1,dirXhalf,posX
	_ENDIF
	sec
	lda	posY
	sta	tmp1
	sbc	dirY
	lda	posY+1
	sta	tmp1+1
	sbc	dirY+1
	sta	posY+1
	jsr	getWorld_XY
	_IFNE
	  lda	tmp1
	  sta	posY
	  lda	tmp1+1
	  sta	posY+1
	_ELSE
	   SUBWABC dirYhalf,tmp1,posY
	_ENDIF
	rts
;;; ----------------------------------------
;;; Calculate world-pointer and return element
;;;

getWorld_XY::
	lda	posY+1
	ldy	#16
	jsr	mulAY
	clc
	adc	#<world
	tay
	lda	MATHE_A+2
	adc	#>world
	sta	world_ptr+1

	clc
	tya
	adc	posX+1
	tay
	_IFCS
	  inc	world_ptr+1
	_ENDIF
	lda	(world_ptr),y
	rts

;;; ----------------------------------------
;;  dirX = -co(angle);
;;  dirY = si(angle);
;;  planeX = 6*si(angle)/8;
;;  planeY = 6*co(angle)/8;

getDirPlane::
	ldx	angle

	lda	sintab_lo+64,x
	sta	tmp0
	clc
	eor	#$ff
	adc	#1
	sta	dirX
	tay
	lda	sintab_hi+64,x
	sta	tmp0+1
	eor	#$ff
	adc	#0
	sta	dirX+1

	cmp	#$80
	ror
	sta	dirXhalf+1
	tya
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
;;; ----------------------------------------
;;; Multiply A:Y by 0.781 (FOV)
;;;
mul6div8::
	sta	MATHE_C
	sty	MATHE_C+1
 IF HALF_REZ = 1
	lda	#180
 ELSE
	lda	#190
 ENDIF
	sta	MATHE_E
	stz	MATHE_E+1
	NOP8
	ldy	MATHE_A+1
	lda	MATHE_A+2
	rts
;;; ----------------------------------------
;;; Multiply x:x+1 by 410 (256*256/160)
;;;
mulX_410::
 IF HALF_REZ = 1
	lda	#<819
	sta	MATHE_C
	lda	#>819
	sta	MATHE_C+1
 ELSE
	lda	#<410
	sta	MATHE_C
	lda	#>410
	sta	MATHE_C+1
 ENDIF
mulX_410_b::
	lda	0,x
	sta	MATHE_E
	lda	1,x
	sta	MATHE_E+1
	NOP8
	lda	MATHE_A+1
	ldy	MATHE_A+2
	ldx	MATHE_A+3
	rts

;;; ----------------------------------------
;;; Multiply A * Y
;;;
mulAY::
	stz	MATHE_E
	sta	MATHE_C		; A = C * E
	sty	MATHE_E+1
	NOP8
	lda	MATHE_A+1
	rts

;;; ----------------------------------------
;;;
lineSCB:
	dc.b SPRCTL0_16_COL|SPRCTL0_NORMAL
	dc.b SPRCTL1_DEPTH_SIZE_RELOAD|SPRCTL1_LITERAL
	dc.b 0
	dc.w 0
line_data:
	dc.w 0
line_x	dc.w 0
	dc.w 51
 IF HALF_REZ = 1
	dc.w $200
 ELSE
	dc.w $100
 ENDIF
line_ysize
	dc.w $100
line_color:
	dc.b $01,$23,$45,$67,$89,$AB,$CD,$EF


;;; ----------------------------------------
;;; horizontal interrupt for the sky

HBL::
	dec	hbl_count
	_IFMI
	  _IFEQ floor
	    clc
	    lda	$fdb0
	    adc	#$10
	    _IFCS
	      lda #18
	      dec floor
	    _ELSE
	      sta $fdb0
	      lda #1
	    _ENDIF
	    sta	hbl_count
	  _ELSE
	    lda #$23
	    sta $fda0
	    sta $fdb0
	    lda #127
	    sta hbl_count
	  _ENDIF
	_ENDIF
	END_IRQ
;;; ----------------------------------------
VBL::
	inc	vbl_count
	lda	#3
	sta	hbl_count
	stz	$fdb0
	stz	$fda0
	stz	floor
	END_IRQ

;;; ----------------------------------------
;;; SCB for sky and floor

skyFloorSCB
	dc.b SPRCTL0_16_COL,SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD,$00
	dc.w 0,cls_data
	dc.w 0,0
	dc.w 160*$100,102*$100
	dc.b $00

cls_data
	dc.b 2,$10,0

;;; ========================================
;;; BLL includes

	include <includes/irq.inc>
	include <includes/debug.inc>
	include <includes/serial.inc>

	include <includes/hexdez.inc>
	include <includes/font.inc>
	include <includes/draw_spr.inc>
pal
;;;          2               6               A
 DP 000,CBC,989,656,424,9B8,8A7,796,685,DEE,ABB,788,555,000,222,FFF

;;; ========================================
;;; local includes

	include "sintab.inc"
	include "deltatab.inc"
SPR_SIZE	equ 130

	include "mandel.inc"
	include "phobyx.inc"
	include "wall1.inc"
	include "door.inc"

;;; ----------------------------------------

textures_lolo:
	dc.b	 <wall1_lo,<phobyx_lo, <mandel_lo,<door_lo
textures_lohi:
	dc.b	 >wall1_lo,>phobyx_lo, >mandel_lo,>door_lo

textures_hilo:
	dc.b	<wall1_hi,<phobyx_hi, <mandel_hi,<door_hi
textures_hihi:
	dc.b	>wall1_hi,>phobyx_hi, >mandel_hi,>door_hi

	align 256
	include "world.inc"

	;; should be last!
	include <includes/font2.hlp>
END::
	echo "END:%H END"
	echo "world:%H world"
	echo "irq_vectors: %H irq_vectors"
	echo "screen0: %Hscreen0"
	echo "screen1: %Hscreen1"
