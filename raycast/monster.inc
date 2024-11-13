;-*-asm-*-
monster:
 ibytes "spr/monster000000.spr"
 ibytes "spr/monster000001.spr"
 ibytes "spr/monster000002.spr"
 ibytes "spr/monster000003.spr"
 ibytes "spr/monster000004.spr"
 ibytes "spr/monster000005.spr"
 ibytes "spr/monster000006.spr"
 ibytes "spr/monster000007.spr"
 ibytes "spr/monster000008.spr"
 ibytes "spr/monster000009.spr"
 ibytes "spr/monster000010.spr"
 ibytes "spr/monster000011.spr"
 ibytes "spr/monster000012.spr"
 ibytes "spr/monster000013.spr"
 ibytes "spr/monster000014.spr"
 ibytes "spr/monster000015.spr"
 ibytes "spr/monster000016.spr"
 ibytes "spr/monster000017.spr"
 ibytes "spr/monster000018.spr"
 ibytes "spr/monster000019.spr"
 ibytes "spr/monster000020.spr"
 ibytes "spr/monster000021.spr"
 ibytes "spr/monster000022.spr"
 ibytes "spr/monster000023.spr"
ma	set monster
monster_lo:
	dc.b 0,0,0,0

	rept 24
	dc.b <ma
ma	set ma+SPR_SIZE
	endr
	dc.b 0,0,0,0

ma	set monster
monster_hi:
	dc.b 0,0,0,0
	rept 24
	dc.b >ma
ma	set ma+SPR_SIZE
	endr
	dc.b 0,0,0,0
