;-*-asm-*-
smileyr:
 ibytes "spr/smiley_right000000.spr"
 ibytes "spr/smiley_right000001.spr"
 ibytes "spr/smiley_right000002.spr"
 ibytes "spr/smiley_right000003.spr"
 ibytes "spr/smiley_right000004.spr"
 ibytes "spr/smiley_right000005.spr"
 ibytes "spr/smiley_right000006.spr"
 ibytes "spr/smiley_right000007.spr"
 ibytes "spr/smiley_right000008.spr"
 ibytes "spr/smiley_right000009.spr"
 ibytes "spr/smiley_right000010.spr"
 ibytes "spr/smiley_right000011.spr"
 ibytes "spr/smiley_right000012.spr"
 ibytes "spr/smiley_right000013.spr"
 ibytes "spr/smiley_right000014.spr"
 ibytes "spr/smiley_right000015.spr"
 ibytes "spr/smiley_right000016.spr"
 ibytes "spr/smiley_right000017.spr"
 ibytes "spr/smiley_right000018.spr"
 ibytes "spr/smiley_right000019.spr"
 ibytes "spr/smiley_right000020.spr"
 ibytes "spr/smiley_right000021.spr"
 ibytes "spr/smiley_right000022.spr"
 ibytes "spr/smiley_right000023.spr"

ma	set smileyr
smileyr_lo:
	dc.b 0,0,0,0

	rept 24
	dc.b <ma
ma	set ma+SPR_SIZE
	endr
	dc.b 0,0,0,0

ma	set smileyr
smileyr_hi:
	dc.b 0,0,0,0
	rept 24
	dc.b >ma
ma	set ma+SPR_SIZE
	endr
	dc.b 0,0,0,0
