;-*-asm-*-
smiley:
 ibytes "spr/smiley000000.spr"
 ibytes "spr/smiley000001.spr"
 ibytes "spr/smiley000002.spr"
 ibytes "spr/smiley000003.spr"
 ibytes "spr/smiley000004.spr"
 ibytes "spr/smiley000005.spr"
 ibytes "spr/smiley000006.spr"
 ibytes "spr/smiley000007.spr"
 ibytes "spr/smiley000008.spr"
 ibytes "spr/smiley000009.spr"
 ibytes "spr/smiley000010.spr"
 ibytes "spr/smiley000011.spr"
 ibytes "spr/smiley000012.spr"
 ibytes "spr/smiley000013.spr"
 ibytes "spr/smiley000014.spr"
 ibytes "spr/smiley000015.spr"
 ibytes "spr/smiley000016.spr"
 ibytes "spr/smiley000017.spr"
 ibytes "spr/smiley000018.spr"
 ibytes "spr/smiley000019.spr"
 ibytes "spr/smiley000020.spr"
 ibytes "spr/smiley000021.spr"
 ibytes "spr/smiley000022.spr"
 ibytes "spr/smiley000023.spr"

ma	set smiley
smiley_lo:
r	dc.b 0,0,0,0
	rept 24
	dc.b <ma
ma	set ma+SPR_SIZE
	endr
	dc.b 0,0,0,0

ma	set smiley
smiley_hi:
	dc.b 0,0,0,0
	rept 24
	dc.b >ma
ma	set ma+SPR_SIZE
	endr
	dc.b 0,0,0,0
