START_X		equ $1b4
START_Y		equ $46a
START_ANGLE	equ 128

MAX_X_REZ	equ 122

HALF_REZ	equ 0

Baudrate	set 62500

BlockSize	equ 1024

IRQ_SWITCHBUF_USR set 1

	include <includes/hardware.inc>
	include <macros/mikey.mac>
	include <macros/suzy.mac>
	include <macros/lnx_header.mac>

	;; fixed address stuff

screen1		equ $FFF0-SCREEN.LEN
screen0		equ screen1-SCREEN.LEN

START_MEM	EQU screen0-1024

	include <macros/help.mac>
	include <macros/if_while.mac>
	include <macros/font.mac>
	include <macros/debug.mac>
	include <macros/irq.mac>
	include <macros/key.mac>

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
vbl_count	ds 2
floor		ds 1
LastButton	ds 1

stepX		ds 1
posX		ds 2
dirX		ds 2
planeX		ds 2
rayDirX		ds 2
sideDistX	ds 2
deltaDistX	ds 2
dirXhalf	ds 2
deltaDistXHalf	ds 2
rayDirX0:	ds 3
rayDirXdelta	ds 3

stepY		ds 1
posY		ds 2
dirY		ds 2
planeY		ds 2
rayDirY		ds 2
sideDistY	ds 2
deltaDistY	ds 2
dirYhalf	ds 2
deltaDistYHalf	ds 2
rayDirY0	ds 3
rayDirYdelta	ds 3

perpWallDist	ds 2
side		ds 1
wallside	ds 1

base_color	ds 1
world_ptr	ds 2
angle		ds 1

lhit		ds 1
hit		ds 1
textureLo	ds 2
textureHi	ds 2

tmp0		ds 2
tmp1		ds 2

step		ds 1

	;; half step variables for frames
sideDist	ds 2
perpDoorDist	ds 2
posXY		ds 2
rayDirXY	ds 2
	;; door variabls
doorInc		ds 1
doorPos		ds 1
doorPtr		ds 2

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

 IFD LNX
	run	0
	LNX_HEADER BlockSize,0,"RAYCAST","42Bastian",0,0

	run 0
	ibytes	<uloader/ml.enc>
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

	INITFONT LITTLEFNT,0,15
	SET_MINMAX 2,2,160,102

	SETIRQ 0,HBL
	SETIRQ 2,VBL

	cli			; don`t forget this !!!!

	SCRBASE screen0,screen1

	SETRGB pal		; set color

	MOVEI 	START_X,posX
	MOVEI 	START_Y,posY
	lda	#START_ANGLE
	sta	angle

	stz	doorInc
	stz	doorPos
	stz	step
.newDirLoop:
	jsr	getDirPlane

;
; main-loop
;
.loop
	SWITCHBUF
	stz	vbl_count

	LDAY skyFloorSCB
	jsr DrawSprite

 IF MAX_X_REZ < 160
	lda	#-(160-MAX_X_REZ)/2
	sta	HOFF
	lda	#$ff
	sta	HOFF+1
 ENDIF
//->	lda	step
//->	_IFNE
//->	  dec	step
//->	_ENDIF
//->	sta	VOFF

;;; rayDirX0 = (dirX+planeX)/2 * FP

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

;;; rayDirY0 = (dirY+planeY)/2 * FP

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

;;; rayDirXDelta = planeX*(256*256/rez_x)

	ldx	#planeX
	jsr	mulX_410
	sta	rayDirXdelta
	sty	rayDirXdelta+1
	stx	rayDirXdelta+2

;;; rayDirYDelta = planeY*(256*256/rez_x)

	ldx	#planeY
	jsr	mulX_410_b
	sta	rayDirYdelta
	sty	rayDirYdelta+1
	stx	rayDirYdelta+2

 IF HALF_REZ = 1
	lda	#MAX_X_REZ/2
 ELSE
	lda	#MAX_X_REZ
 ENDIF
	sta	lhit		; preset last texture
	jmp	.intoloop
.xloop
//->	lda	#$01
//->	sta	line_color

	lda	posX
	sta	sideDistX
	stz	sideDistX+1
	lda	posY
	sta	sideDistY
	stz	sideDistY+1

;;; rayDirX = rayDirX0/FP
;;; rayDirX0 -= rayDirXdelta
	sec
	lda	rayDirX0
	sbc	rayDirXdelta
	sta	rayDirX0
	lda	rayDirX0+1
	sta	rayDirX
	tax			; save for later
	sbc	rayDirXdelta+1
	sta	rayDirX0+1
	lda	rayDirX0+2
	sta	rayDirX+1
	sbc	rayDirXdelta+2
	sta	rayDirX0+2

;;      deltaDistX = deltaTable[abs(rayDirX)];
;;
;;      if (rayDirX < 0) {
;;        stepX = -1;
;;        sideDistX = sideDistX * deltaDistX/fp;
;;      } else {
;;        stepX = 1;
;;        sideDistX = (fp - sideDistX) * deltaDistX/fp;
;;      }
;;    }


	ldy	#$01		; stepX

	bbr7	rayDirX+1,.rayDirPlus

	txa
	eor	#$ff
	inc
	tax
	ldy	#$ff
.rayDirPlus
	lda	sideDistX
	sty	stepX
	iny
	beq	.rayDirMinus	; stepX < 0 =>

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

	lda	deltaDistX+1
	cmp	#$80
	ror
	sta	deltaDistXHalf+1
	lda	deltaDistX
	ror
	sta	deltaDistXHalf

;;; rayDirY = rayDirY0/FP
;;; rayDirY0 -= rayDirYdelta

	sec
	lda	rayDirY0
	sbc	rayDirYdelta
	sta	rayDirY0
	lda	rayDirY0+1
	sta	rayDirY
	tax
	sbc	rayDirYdelta+1
	sta	rayDirY0+1
	lda	rayDirY0+2
	sta	rayDirY+1
	sbc	rayDirYdelta+2
	sta	rayDirY0+2

;;      deltaDistY = deltaTab(abs(rayDirY));
;;
;;      if (rayDirY > 0) {
;;        stepY = -1;
;;        sideDistY = sideDistY * deltaDistY/fp;
;;      } else {
;;        stepY = 1;
;;        sideDistY = (fp - sideDistY) * deltaDistY/fp;
;;      }

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
	tay
	sta	MATHE_E
	lda	deltatab_hi,x
	sta	deltaDistY+1
	tax
	sta	MATHE_E+1
	NOP8
	lda	MATHE_A+1
	sta	sideDistY
	lda	MATHE_A+2
	sta	sideDistY+1

	txa
	cmp	#$80
	ror
	sta	deltaDistYHalf+1
	tya
	ror
	sta	deltaDistYHalf

	jsr	getWorld_XY
.rescan:
	jsr	scanMap

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
	ldy	side
	bne	.left_right
	bit	stepX
	SKIP2
.left_right
	bit	stepY
	bmi	.done_wallside
	iny
.done_wallside
	sty	wallside

	ldy	#1
	sty	line_color

	cmp	#1
	_IFNE
	  tax
	  and	#3
	  sta	base_color
	  clc
	  adc	base_color
	  _IFNE
	    sta	line_color
	  _ENDIF
	_ENDIF

;; if (side == 0) wallX = (posY - perpWallDist * rayDirY/fp);
;; else           wallX = (posX + perpWallDist * rayDirX/fp);

	lda	hit
	cmp	#3<<2
	beq	.door
	cmp	#3<<2|3
	_IFEQ
.door
	  CMPWS sideDist,perpDoorDist
	  _IFCS
	    ldy	world_ptr
	    stz	world_ptr
	    bra .rescan
	  _ENDIF
	  lda	perpDoorDist
	  sta	MATHE_B
	  asl
	  sta	MATHE_C
	  lda	perpDoorDist+1
	  sta	MATHE_B+1
	  rol
	  sta	MATHE_C+1
	  lda	rayDirXY
	  asl
	  sta	MATHE_E
	  lda	rayDirXY+1
	  rol
	  sta	MATHE_E+1
	  NOP8
	  lda	MATHE_A+2
	  lsr
	  lda	MATHE_A+1
	  ror
	  clc
	  adc	posXY
	_ELSE
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
	  asl
	  sta	MATHE_E
	  lda	rayDirX+1
	  rol
	  sta	MATHE_E+1
	  NOP8
	  lda	MATHE_A+2
	  lsr
	  lda	MATHE_A+1
	  ror
	  clc
	  adc	posX
	  bra	.t9
.t1
	  lda	rayDirY
	  asl
	  sta	MATHE_E
	  lda	rayDirY+1
	  rol
	  sta	MATHE_E+1
	  NOP8
	  lda	MATHE_A+2
	  lsr
	  lda	MATHE_A+1
	  ror
	  eor	#$ff
	  sec
	  adc	posY
.t9
	_ENDIF
	stz	MATHE_A
	ldx	#<(102*8)
	stx	MATHE_A+2
	ldx	#>(102*8)
	stx	MATHE_A+3	; start divide (*4 => /64)

	lsr
	lsr
	lsr
	tay			; texX

	lda	hit		; wall element

	cmp	#3<<2|3
	bne	.no_door	; not a moving door

	cpy	doorPos
	bcc	.moving_door
.do_rescan
	ldy	world_ptr
	stz	world_ptr
	jmp	.rescan

.moving_door:
	sec
	tya
	sbc	doorPos
	and	#31
	tay
.no_door

	lda	hit
	bpl	.no_flag
	and	#3
	cmp	wallside
	_IFEQ
	  lda	#4<<2
	_ELSE
	  lda	#1<<2
	_ENDIF
.no_flag
	lsr
	lsr			; remove flags/color

.found_texture:
	tax
	cpx	lhit
	_IFNE
	  stx	lhit
	  lda	textures_lolo,x
	  sta	textureLo
	  lda	textures_lohi,x
	  sta	textureLo+1
	  lda	textures_hilo,x
	  sta	textureHi
	  lda	textures_hihi,x
	  sta	textureHi+1
	  txa
	_ENDIF

	cpx	#3
	beq	.no_mirror

	bbs0	wallside,.no_mirror
	tya
	eor	#31
	tay
.no_mirror

	lda	(textureLo),y
	sta	line_data
	lda	(textureHi),y
	sta	line_data+1
	LDAY	lineSCB

	WAITSUZY		; wait for divide to finish

	ldx	MATHE_D+1
	stx	line_ysize
	ldx	MATHE_D+2
	stx	line_ysize+1

	jsr	DrawSprite

	pla
	beq	.done
.intoloop
	dec
	pha
 IF HALF_REZ = 1
	asl
 ENDIF
	sta	line_x
	jmp	.xloop
.done
 IF 0 = 1
	;; check how many cycles are left before next VBL
	;; => time for game logic
//->	ldy	#1
	ldx	#140
.eat_cycles
	NOP8
	dex
	bne	.eat_cycles
//->	dey
//->	bne	.eat_cycles
 ENDIF

	lda	doorInc
	_IFNE
	  clc
	  adc	doorPos
	  sta	doorPos
	  _IFEQ
	    stz	doorInc
	    lda	(doorPtr)
	    and	#$fe
	    sta (doorPtr)
	  _ELSE
	    cmp #32
	    _IFEQ
	      stz doorInc
	      lda (doorPtr)
	      and #$fc
	      sta (doorPtr)
	    _ENDIF
	  _ENDIF
	_ENDIF
	lda	vbl_count
	pha

	stz	VOFF
 IF MAX_X_REZ < 160
	stz	HOFF
 ENDIF
	SET_XY 2,2
	PRINT info

	SET_XY 2,9
	lda posX+1
	jsr PrintHex
	lda posX
	jsr PrintHex

	SET_XY 2,23
	lda posY+1
	jsr PrintHex
	lda posY
	jsr PrintHex

	SET_XY 2,37
	lda angle
	jsr PrintDecA

	SET_XY 2,51
	pla
	jsr PrintDecA

.0
	READKEY		; see MIKEY.MAC
	beq	.no_button
	tax
	eor	LastButton
	stx	LastButton
	beq	.no_button1

	and #_FLIP	; Pause+Opt2 => Flip
	cmp #_FLIP
	_IFEQ
	  FLIP
	_ENDIF
	lda	Button
	bit	#_FIREB
	_IFNE
	  jsr checkForDoor
	  tax
	  and	#3<<2
	  cmp	#3<<2
	  bne .cont

	  lda	doorInc
	  _IFNE
	    eor	#$ff
	    inc
	    sta doorInc
	  _ELSE
	     txa
	     bit #2
	     _IFNE
	       stz doorPos
	       ldy #4
	     _ELSE
	       ldy #32
	       sty doorPos
	       ldy #-4
	     _ENDIF
	     sty doorInc
	     ora #3
	     sta (doorPtr)
	  _ENDIF
	_ENDIF
.cont
	jmp	.loop

.no_button:
	stz	LastButton
.no_button1:
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

info:	dc.b "X:",13,13,"Y:",13,13,"A:",13,13,"VBL:",0
;;; ----------------------------------------
;;->        if (sideDistX < sideDistY) {
;;->          perpWallDist = sideDistX;
;;->          sideDistX += deltaDistX;
;;->          mapX += stepX;
;;->          wallside = ( stepX < 0 ) ? 1 : 2;
;;->          wallX = (posY/2 - perpWallDist * rayDirY/fp);
;;->
;;->          pos = posY;
;;->          rd = -rayDirY;
;;->          dperp = perpWallDist+deltaDistX/2;
;;->          sideDist = sideDistY;
;;->        } else {
;;->          perpWallDist = sideDistY;
;;->          sideDistY += deltaDistY;
;;->          mapY += stepY;
;;->          wallside = (stepY > 0 ) ? 3 : 4;
;;->          wallX = (posX/2 + perpWallDist * rayDirX/fp);
;;->
;;->          rd = rayDirX;
;;->          pos = posX;
;;->          dperp = perpWallDist+deltaDistY/2;
;;->          sideDist = sideDistX;
;;->        }

scanMap::
scanMapCont:

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

	  MOVE	sideDistY,sideDist
	  MOVE	posY,posXY
	  sec
	  lda	#0
	  sbc	rayDirY
	  sta	rayDirXY
	  lda	#0
	  sbc	rayDirY+1
	  sta	rayDirXY+1
	  ADDWABC perpWallDist,deltaDistXHalf,perpDoorDist

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

	  MOVE	posX,posXY
	  MOVE	sideDistX,sideDist
	  MOVE	rayDirX,rayDirXY
	  ADDWABC perpWallDist,deltaDistYHalf,perpDoorDist

	  sec
	  tya
	  sbc	stepY
	_ENDIF
	tay
	lda	(world_ptr),y
	beq	.wallloop1
	cmp	#3<<2|2
	bne	.done
.wallloop1:
	jmp	.wallloop
.done
	sty	world_ptr
	stx	side
	sta	hit
	rts

;;; ----------------------------------------
;;; Check if we stand in front of a door
checkForDoor::
	sec
	lda	posY
	sbc	dirY
	tax
	lda	posY+1
	sbc	dirY+1
	tay
	sec
	txa
	sbc	dirYhalf
	tya
	sbc	dirYhalf+1
	asl
	asl
	asl
	asl
	sta	tmp0

	clc
	lda	posX
	adc	dirX
	tax
	lda	posX+1
	adc	dirX+1
	tay
	clc
	txa
	adc	dirXhalf
	tya
	adc	dirXhalf+1

	clc
	adc	tmp0
	sta	doorPtr
	lda	#0
	adc	#>world
	sta	doorPtr+1
	lda	(doorPtr)
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
	beq	.ok
	cmp	#3<<2|2
	beq	.ok
	  lda	tmp1
	  sta	posX
	  lda	tmp1+1
	  sta	posX+1
	bra	.cont
.ok
	  SUBWABC dirXhalf,tmp1,posX
.cont
	clc
	lda	posY
	sta	tmp1
	adc	dirY
	lda	posY+1
	sta	tmp1+1
	adc	dirY+1
	sta	posY+1
	jsr	getWorld_XY
	beq	.ok1
	cmp	#3<<2|2
	beq	.ok1
	  lda	tmp1
	  sta	posY
	  lda	tmp1+1
	  sta	posY+1
	  rts
.ok1
	   ADDWABC dirYhalf,tmp1,posY
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
	beq	.ok
	cmp	#3<<2|2
	beq	.ok
	   lda	tmp1
	   sta	posX
	   lda	tmp1+1
	   sta	posX+1
	bra	.cont
.ok
	  ADDWABC tmp1,dirXhalf,posX
.cont
	sec
	lda	posY
	sta	tmp1
	sbc	dirY
	lda	posY+1
	sta	tmp1+1
	sbc	dirY+1
	sta	posY+1
	jsr	getWorld_XY
	beq	.ok1
	cmp	#3<<2|2
	beq	.ok1

	  lda	tmp1
	  sta	posY
	  lda	tmp1+1
	  sta	posY+1
	rts
.ok1:
	   SUBWABC dirYhalf,tmp1,posY
	rts
;;; ----------------------------------------
;;; Calculate world-pointer and return element
;;;

getWorld_XY::
	lda	posY+1		; posY < 16 !!
	asl
	asl
	asl
	asl
//->	clc
//->	adc	#<world		; aligned on 256!

//->	clc
	adc	posX+1
	tay
	lda	#0
	adc	#>world
	stz	world_ptr
	sta	world_ptr+1
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
	lda	#MAX_X_REZ+30
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
	lda	#<(256*256/MAX_X_REZ)
	sta	MATHE_C
	lda	#>(256*256/MAX_X_REZ)
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
//->	READKEY
	IRQ_SWITCHBUF
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
	dc.b SPRCTL0_16_COL
	dc.b SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD
	dc.b $00
 IF MAX_X_REZ < 160
	dc.w skyFloorSCB2
 ELSE
	dc.w 0
 ENDIF
	dc.w cls_data
	dc.w (160-MAX_X_REZ)/2,0
	dc.w MAX_X_REZ*$100,102*$100
	dc.b $00

 IF MAX_X_REZ < 160
skyFloorSCB2
	dc.b SPRCTL0_16_COL
	dc.b SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD,$00
	dc.w skyFloorSCB2a
	dc.w cls_data
	dc.w 0,0
	dc.w (160-MAX_X_REZ)*$80,102*$100
	dc.b $03
skyFloorSCB2a
	dc.b SPRCTL0_16_COL
	dc.b SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD,$00
	dc.w skyFloorSCB3
	dc.w cls_data
	dc.w 1,1
	dc.w (160-MAX_X_REZ-4)*$80,100*$100
	dc.b $01

skyFloorSCB3
	dc.b SPRCTL0_16_COL
	dc.b SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD,$00
	dc.w skyFloorSCB3a
	dc.w cls_data
	dc.w (160+MAX_X_REZ)/2,0
	dc.w (160-MAX_X_REZ)*$80,102*$100
	dc.b $03
skyFloorSCB3a
	dc.b SPRCTL0_16_COL
	dc.b SPRCTL1_LITERAL|SPRCTL1_DEPTH_SIZE_RELOAD,$00
	dc.w 0
	dc.w cls_data
	dc.w (160+MAX_X_REZ)/2+1,1
	dc.w (160-MAX_X_REZ-4)*$80,100*$100
	dc.b $01
 ENDIF

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

SPR_SIZE	equ 66

	include "mandel.inc"
	include "phobyx.inc"
	include "wall1.inc"
	include "door.inc"
	include "frame.inc"

;;; ----------------------------------------

textures_lolo:
	dc.b	 <wall1_lo,<phobyx_lo, <mandel_lo,<door_lo,<frame_lo
textures_lohi:
	dc.b	 >wall1_lo,>phobyx_lo, >mandel_lo,>door_lo,>frame_lo

textures_hilo:
	dc.b	<wall1_hi,<phobyx_hi, <mandel_hi,<door_hi,<frame_hi
textures_hihi:
	dc.b	>wall1_hi,>phobyx_hi, >mandel_hi,>door_hi,>frame_hi

	align 256
	include "world.inc"

	;; should be last!
	include <includes/font2.hlp>
end:
	echo "END:%H end"
	echo "world:%H world"
	echo "irq_vectors: %H irq_vectors"
	echo "screen0: %Hscreen0"
	echo "screen1: %Hscreen1"
