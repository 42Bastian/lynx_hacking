;-*-asm-*-
smileyb:
 ibytes "spr/smiley_back000000.spr"
 ibytes "spr/smiley_back000001.spr"
 ibytes "spr/smiley_back000002.spr"
 ibytes "spr/smiley_back000003.spr"
 ibytes "spr/smiley_back000004.spr"
 ibytes "spr/smiley_back000005.spr"
 ibytes "spr/smiley_back000006.spr"
 ibytes "spr/smiley_back000007.spr"
 ibytes "spr/smiley_back000008.spr"
 ibytes "spr/smiley_back000009.spr"
 ibytes "spr/smiley_back000010.spr"
 ibytes "spr/smiley_back000011.spr"
 ibytes "spr/smiley_back000012.spr"
 ibytes "spr/smiley_back000013.spr"
 ibytes "spr/smiley_back000014.spr"
 ibytes "spr/smiley_back000015.spr"
 ibytes "spr/smiley_back000016.spr"
 ibytes "spr/smiley_back000017.spr"
 ibytes "spr/smiley_back000018.spr"
 ibytes "spr/smiley_back000019.spr"
 ibytes "spr/smiley_back000020.spr"
 ibytes "spr/smiley_back000021.spr"
 ibytes "spr/smiley_back000022.spr"
 ibytes "spr/smiley_back000023.spr"

ma	set smileyb
smileyb_lo:
	dc.b 0,0,0,0

	rept 24
	dc.b <ma
ma	set ma+SPR_SIZE
	endr
	dc.b 0,0,0,0

ma	set smileyb
smileyb_hi:
	dc.b 0,0,0,0
	rept 24
	dc.b >ma
ma	set ma+SPR_SIZE
	endr
	dc.b 0,0,0,0
