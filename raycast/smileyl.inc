;-*-asm-*-
smileyl:
 ibytes "spr/smiley_left000000.spr"
 ibytes "spr/smiley_left000001.spr"
 ibytes "spr/smiley_left000002.spr"
 ibytes "spr/smiley_left000003.spr"
 ibytes "spr/smiley_left000004.spr"
 ibytes "spr/smiley_left000005.spr"
 ibytes "spr/smiley_left000006.spr"
 ibytes "spr/smiley_left000007.spr"
 ibytes "spr/smiley_left000008.spr"
 ibytes "spr/smiley_left000009.spr"
 ibytes "spr/smiley_left000010.spr"
 ibytes "spr/smiley_left000011.spr"
 ibytes "spr/smiley_left000012.spr"
 ibytes "spr/smiley_left000013.spr"
 ibytes "spr/smiley_left000014.spr"
 ibytes "spr/smiley_left000015.spr"
 ibytes "spr/smiley_left000016.spr"
 ibytes "spr/smiley_left000017.spr"
 ibytes "spr/smiley_left000018.spr"
 ibytes "spr/smiley_left000019.spr"
 ibytes "spr/smiley_left000020.spr"
 ibytes "spr/smiley_left000021.spr"
 ibytes "spr/smiley_left000022.spr"
 ibytes "spr/smiley_left000023.spr"

ma	set smileyl
smileyl_lo:
	dc.b 0,0,0,0

	rept 24
	dc.b <ma
ma	set ma+SPR_SIZE
	endr
	dc.b 0,0,0,0

ma	set smileyl
smileyl_hi:
	dc.b 0,0,0,0
	rept 24
	dc.b >ma
ma	set ma+SPR_SIZE
	endr
	dc.b 0,0,0,0
